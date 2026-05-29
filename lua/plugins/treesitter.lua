return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      -- 1. Initialize the modern setup framework
      ts.setup({})

      -- 2. Modern way to ensure parsers are safely installed 
      -- (This is a fast no-op if they are already installed)
      ts.install({ 
        "c", "cpp", "lua", "vim", "vimdoc", "query", 
        "markdown", "markdown_inline", "python", "qmljs",
        "svelte", "html", "css", "javascript", "typescript",
      })

      -- 3. THE FIX: Explicitly activate native highlighting and indentation
      -- whenever you open a file matching these types
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { 
          "c", "cpp", "lua", "vim", "markdown", "python", 
          "svelte", "html", "css", "javascript", "typescript" 
        },
        callback = function(event)
          -- Safely start native Tree-sitter highlighting
          pcall(vim.treesitter.start, event.buf)
          
          -- Activate Tree-sitter based code indentation
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
