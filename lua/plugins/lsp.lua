return {
    "neovim/nvim-lspconfig",
    dependencies = {
        { "j-hui/fidget.nvim", opts = {} },
        { "williamboman/mason.nvim", opts = {} }, -- Installs the Mason UI toolbox
        { 
            "williamboman/mason-lspconfig.nvim",
            opts = {
                -- The magic list: Mason will auto-download these if they are missing!
                ensure_installed = {
                    "lua_ls",
                    "pyright",
                    "dockerls",
                    "docker_compose_language_service",
                    "html",
                    "svelte"
                }
            }
        },
    },
    config = function()
        -- 1. SETUP GLOBAL CAPABILITIES (Required for HTML autocomplete snippets)
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.textDocument.completion.completionItem.snippetSupport = true


        -- 2. SVELTE LSP CONFIGURATION
        local svelte_config = {
            cmd = { 'svelteserver', '--stdio' },
            filetypes = { 'svelte' },
            settings = {
                typescript = {
                    inlayHints = {
                        parameterNames = { enabled = 'literals', suppressWhenArgumentMatchesName = true },
                        parameterTypes = { enabled = true },
                        variableTypes = { enabled = true },
                        propertyDeclarationTypes = { enabled = true },
                        functionLikeReturnTypes = { enabled = true },
                        enumMemberValues = { enabled = true },
                    },
                },
            },
            root_dir = function(bufnr, on_dir)
                local fname = vim.api.nvim_buf_get_name(bufnr)
                if vim.uv.fs_stat(fname) ~= nil then
                    local root_markers = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock', 'deno.lock' }
                    root_markers = vim.fn.has('nvim-0.11.3') == 1 and { root_markers, { '.git' } } or vim.list_extend(root_markers, { '.git' })
                    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()
                    on_dir(project_root)
                end
            end,
            on_attach = function(client, bufnr)
                vim.api.nvim_create_autocmd('BufWritePost', {
                    pattern = { '*.js', '*.ts' },
                    group = vim.api.nvim_create_augroup('lspconfig.svelte', {}),
                    callback = function(ctx)
                        client:notify('$/onDidChangeTsOrJsFile', { uri = ctx.match })
                    end,
                })
                vim.api.nvim_buf_create_user_command(bufnr, 'LspMigrateToSvelte5', function()
                    client:exec_cmd({
                        title = 'Migrate Component to Svelte 5 Syntax',
                        command = 'migrate_to_svelte_5',
                        arguments = { vim.uri_from_bufnr(bufnr) },
                    })
                end, { desc = 'Migrate Component to Svelte 5 Syntax' })
            end,
        }


        -- 3. HTML LSP CONFIGURATION (Your newly copied config)
        local html_config = {
            capabilities = capabilities, -- Injects the snippet support we defined above
            cmd = function(dispatchers, config)
                local cmd = 'vscode-html-language-server'
                if (config or {}).root_dir then
                    local local_cmd = vim.fs.joinpath(config.root_dir, 'node_modules/.bin', cmd)
                    if vim.fn.executable(local_cmd) == 1 then
                        cmd = local_cmd
                    end
                end
                return vim.lsp.rpc.start({ cmd, '--stdio' }, dispatchers)
            end,
            filetypes = { 'html' },
            root_markers = { 'package.json', '.git' },
            settings = {},
            init_options = {
                provideFormatter = true,
                embeddedLanguages = { css = true, javascript = true },
                configurationSection = { 'html', 'css', 'javascript' },
            },
        }

        local function set_python_path(command)
            local path = command.args
            local clients = vim.lsp.get_clients {
                bufnr = vim.api.nvim_get_current_buf(),
                name = 'pyright',
            }
            for _, client in ipairs(clients) do
                if client.settings then
                    client.settings.python =
                    vim.tbl_deep_extend('force', client.settings.python --[[@as table]], { pythonPath = path })
                else
                    client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
                end
                client:notify('workspace/didChangeConfiguration', { settings = nil })
            end
        end

        local python_config = {
            ---@brief
            ---
            --- https://github.com/microsoft/pyright
            ---
            --- `pyright`, a static type checker and language server for python
            ---@type vim.lsp.Config
            cmd = { 'pyright-langserver', '--stdio' },
            filetypes = { 'python' },
            root_markers = {
                'pyrightconfig.json',
                'pyproject.toml',
                'setup.py',
                'setup.cfg',
                'requirements.txt',
                'Pipfile',
                '.git',
            },
            --           ---@type lspconfig.settings.pyright
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        useLibraryCodeForTypes = true,
                        diagnosticMode = 'openFilesOnly',
                    },
                },
            },

            before_init = function(params, config)
                -- List the environment folder names you use (like 'backend' or '.venv')
                local venv_paths = { 'backend', '.venv', 'venv' }

                for _, path in ipairs(venv_paths) do
                    -- Look inside your current working directory for the python binary
                    local local_python = vim.fs.joinpath(vim.fn.getcwd(), path, 'bin', 'python')

                    -- If the binary exists, assign it to Pyright automatically
                    if vim.fn.executable(local_python) == 1 then
                        config.settings.python.pythonPath = local_python
                        return
                    end
                end

                -- Fallback: If you activated the environment in your terminal before opening nvim
                if vim.env.VIRTUAL_ENV then
                    config.settings.python.pythonPath = vim.fs.joinpath(vim.env.VIRTUAL_ENV, 'bin', 'python')
                end
            end,
            on_attach = function(client, bufnr)
                vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
                    local params = {
                        command = 'pyright.organizeimports',
                        arguments = { vim.uri_from_bufnr(bufnr) },
                    }

                    -- Using client.request() directly because "pyright.organizeimports" is private
                    -- (not advertised via capabilities), which client:exec_cmd() refuses to call.
                    -- https://github.com/neovim/neovim/blob/c333d64663d3b6e0dd9aa440e433d346af4a3d81/runtime/lua/vim/lsp/client.lua#L1024-L1030
                    ---@diagnostic disable-next-line: param-type-mismatch
                    client.request('workspace/executeCommand', params, nil, bufnr)
                end, {
                        desc = 'Organize Imports',
                    })
                vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
                    desc = 'Reconfigure pyright with the provided python path',
                    nargs = 1,
                    complete = 'file',
                })
            end,
        }

        local docker_config = {

            cmd = { 'docker-langserver', '--stdio' },
            filetypes = { 'dockerfile' },
            root_markers = { 'Dockerfile' },
        }

        local docker_compose_config = {
            cmd = { 'docker-compose-langserver', '--stdio' },
            filetypes = { 'yaml.docker-compose' },
            root_markers = { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml' },
        }

        vim.filetype.add({
            filename = {
                ['docker-compose.yml'] = 'yaml.docker-compose',
                ['docker-compose.yaml'] = 'yaml.docker-compose',
                ['compose.yml'] = 'yaml.docker-compose',
                ['compose.yaml'] = 'yaml.docker-compose',
            },
        })

        local root_markers1 = { '.emmyrc.json', '.luarc.json', '.luarc.jsonc' }
        local root_markers2 = { '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml' }

        local lua_config = {
            cmd = { 'lua-language-server' },
            filetypes = { 'lua' },
            root_markers = vim.fn.has('nvim-0.11.3') == 1 and { root_markers1, root_markers2, { '.git' } }
                or vim.list_extend(vim.list_extend(root_markers1, root_markers2), { '.git' }),
            on_init = function(client)
                if client.workspace_folders then
                    local path = client.workspace_folders[1].name
                    if path ~= vim.fn.stdpath('config')
                        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                    then
                        return
                    end
                end

                client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                    runtime = {
                        version = 'LuaJIT',
                        path = { 'lua/?.lua', 'lua/?/init.lua' },
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = {
                            vim.env.VIMRUNTIME,
                        },
                    },
                })
            end,
            settings = {
                Lua = {
                    codeLens = { enable = true },
                    hint = { enable = true, semicolon = 'Disable' },
                },
            },
        }

        local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
        vim.env.PATH = mason_bin .. ":" .. vim.env.PATH


        -- 4. REGISTER AND ENABLE BOTH SERVERS
        vim.lsp.config('svelte', svelte_config)
        vim.lsp.enable('svelte')

        vim.lsp.config('html', html_config)
        vim.lsp.enable('html')

        vim.lsp.config('pyright', python_config)
        vim.lsp.enable('pyright')

        vim.lsp.config('dockerls',docker_config)
        vim.lsp.enable('dockerls')

        vim.lsp.config('docker_compose_language_server',docker_compose_config)
        vim.lsp.enable('docker_compose_language_server')

        vim.lsp.config('lua_ls', lua_config)
        vim.lsp.enable('lua_ls')


        -- 5. GLOBAL LSP KEYMAPS (Runs whenever any LSP attaches)
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(event)
                local opts = { buffer = event.buf }
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = "Go to Definition" }))
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = "Show References" }))
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = "Hover Documentation" }))
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = "Rename Symbol" }))
                vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = "Code Actions" }))
                vim.keymap.set('n', 'gl', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = "Show Line Diagnostics" }))
            end,
        })
    end
}
