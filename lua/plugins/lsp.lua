return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "j-hui/fidget.nvim", opts = {} }, 
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


    -- 4. REGISTER AND ENABLE BOTH SERVERS
    vim.lsp.config('svelte', svelte_config)
    vim.lsp.enable('svelte')

    vim.lsp.config('html', html_config)
    vim.lsp.enable('html')


    -- 5. GLOBAL LSP KEYMAPS (Runs whenever any LSP attaches)
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(event)
        local opts = { buffer = event.buf }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = "Go to Definition" }))
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = "Show References" }))
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = "Hover Documentation" }))
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = "Rename Symbol" }))
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = "Code Actions" }))
      end,
    })
  end
}
