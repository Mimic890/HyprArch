vim.opt.termguicolors = true
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 30, side = "left" },
        renderer = { group_empty = true },
        filters = { dotfiles = false },
      })
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.pyright.setup({})
    end,
  },
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "*", -- все типы файлов
        css = { rgb_fn = true, rgba_fn = true, css = true, css_fn = true },
        html = { names = false },
      }, {
        RGB = true,
        RRGGBB = true,
        names = true,
        RRGGBBAA = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
      })
    end,
  },
})
require("catppuccin").setup({
  flavour = "mocha",
  integrations = {
    treesitter = true,
    telescope = true,
    cmp = true,
    gitsigns = true,
    nvimtree = true,
  },
})
vim.cmd.colorscheme("catppuccin")
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.tabstop = 4
vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<S-Space>", ":term<CR>", { noremap = true, silent = true })
