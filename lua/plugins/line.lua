return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {
        indent = {
            char = "┃", -- 💡 Thick background lines
            highlight = "IblPassiveLine",
        },
        scope = {
            enabled = true,
            char = "┃", -- 💡 Thick active scope line
            show_start = false,
            show_end = false,
            highlight = "IblActiveScope",
        },
    },
    init = function()
        vim.api.nvim_set_hl(0, "IblPassiveLine", { fg = "#515151" })
        vim.api.nvim_set_hl(0, "IblActiveScope", { fg = "#7c7c7c" })
    end,
}
