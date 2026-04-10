return {

    {

        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            -- NOTE: 'nvim-treesitter.configs' is gone. 
            -- Use the main module instead.
            require("nvim-treesitter").setup({

                -- ensure_installed is still the best way to prevent the download loop
                ensure_installed = { 
                    "c", "cpp", "lua", "vim", "vimdoc", "query", 
                    "markdown", "markdown_inline", "python" 
                },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },
}
