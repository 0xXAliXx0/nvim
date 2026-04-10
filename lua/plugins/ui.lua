
return {{ "catppuccin/nvim", name = "catppuccin", priority = 1000,
config = function()
    require("catppuccin").setup({
        integrations = {
            treesitter = true,
            native_lsp = {
                enabled = true,
                virtual_text = {
                    errors = { "italic" },
                    hints = { "italic" },
                    warnings = { "italic" },
                    information = { "italic" },
                },
            },
            indent_blankline = {
                enabled = true,
                scope_color = "lavender", -- Makes your bracket lines look better
            },
        },
    })
    vim.cmd.colorscheme "catppuccin"
end,
},
{
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup()
    end,
},
}
