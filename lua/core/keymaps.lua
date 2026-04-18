
            --vim.keymap.set('n', '<leader>n',':Neotree filesystem reveal left<CR>', {})
            vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = "Toggle Neo-tree" })
            vim.keymap.set('i','jj','<ESC>')
            vim.keymap.set('n','<leader>w',':w<CR>')
            --vim.keymap.set('i', '<Esc>', '~', { noremap = true })
            vim.keymap.set('i', '<C-h>','<Left>')
            vim.keymap.set('i', '<C-j>','<Down>')
            vim.keymap.set('i', '<C-k>','<Up>')
            vim.keymap.set('i', '<C-l>','<Right>')
            vim.keymap.set('n', '<leader>t', ':TransparentToggle<CR>')

local function lunch_terminal()
   -- local dir = vim.fn.getcwd()
   
   -- Get the full path of the current buffer
    local current_file = vim.api.nvim_buf_get_name(0)--0 represents the buffer
    
    -- Extract the directory path (head) from the file path
    -- If the buffer is empty, it defaults to the CWD
    local dir = vim.fn.fnamemodify(current_file, ":p:h")
    --:p expands the path to be fully qualified.
    --:h (head) removes the last component (the filename), leaving you with just the directory.

    vim.fn.jobstart({ "foot", "-D", dir }, { detach = true })
end
            vim.keymap.set('n','<leader>q',lunch_terminal)

