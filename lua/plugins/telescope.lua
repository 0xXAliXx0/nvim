return{
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local builtin = require("telescope.builtin")
            vim.keymap.set('n', '<leader>ff',builtin.find_files, {})
            vim.keymap.set('n', '<leader>fg',builtin.live_grep, {})

            --vim.keymap.set('n', '<leader>n',':Neotree filesystem reveal left<CR>', {})
            vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = "Toggle Neo-tree" })
            vim.keymap.set('i','jj','<ESC>')
            vim.keymap.set('n','<leader>w',':w<CR>')
            --vim.keymap.set('i', '<Esc>', '~', { noremap = true })
            vim.keymap.set('i', '<C-h>','<Left>')
            vim.keymap.set('i', '<C-j>','<Down>')
            vim.keymap.set('i', '<C-k>','<Up>')
            vim.keymap.set('i', '<C-l>','<Right>')

        end,

    },
}
