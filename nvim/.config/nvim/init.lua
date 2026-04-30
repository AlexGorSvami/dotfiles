-- ==============================================================================
-- 1. СИСТЕМНЫЕ НАСТРОЙКИ (Manjaro Linux, 24h формат)
-- ==============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Русская раскладка (навигация без переключения языка)
vim.opt.langmap = 'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz'

vim.opt.number = true           -- Номера строк
vim.opt.relativenumber = true   -- Относительные номера
vim.opt.shiftwidth = 4          -- Табуляция 4 пробела
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus" -- Системный буфер (требуется xclip)
vim.opt.mouse = "a"
vim.opt.undofile = true         -- Сохранение истории

-- ==============================================================================
-- 2. ПЛАГИНЫ (Lazy.nvim)
-- ==============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Тема Kanagawa и полная прозрачность
  { "rebelot/kanagawa.nvim", priority = 1000, config = function()
      require("kanagawa").setup({ transparent = true, theme = "wave" })
      vim.cmd("colorscheme kanagawa")
      -- Принудительная прозрачность всех панелей
      local groups = { "Normal", "NormalNC", "LineNr", "SignColumn", "StatusLine", "EndOfBuffer" }
      for _, group in ipairs(groups) do vim.api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" }) end
    end 
  },

  -- Удобство и Визуал
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} }, -- Линии отступов
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, config = true },
  { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" } },
  { "nvim-telescope/telescope.nvim", tag = "0.1.5", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Инструменты разработки
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function()
      require("nvim-treesitter.configs").setup({ ensure_installed = { "python", "pascal", "lua", "c" }, highlight = { enable = true } })
    end
  },
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
  { "numToStr/Comment.nvim", config = true },

  -- LSP, Сниппеты и Автодополнение
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp", dependencies = { 
      "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip" 
    } 
  },

  -- Отладка (DAP)
  { "mfussenegger/nvim-dap", dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" } },
  { "mfussenegger/nvim-dap-python" },
})

-- ==============================================================================
-- 3. LSP (Native API Neovim 0.11+)
-- ==============================================================================
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Pascal (pasls - настраиваем вручную, как просил)
vim.lsp.config('pasls', { cmd = { "pasls" }, capabilities = capabilities, filetypes = { "pascal", "pp", "inc" } })
vim.lsp.enable('pasls')

-- Остальные (Python, C)
local servers = { "pyright", "clangd" }
for _, s in ipairs(servers) do
    vim.lsp.config(s, { capabilities = capabilities })
    vim.lsp.enable(s)
end

-- ==============================================================================
-- 4. ИСПРАВЛЕННЫЙ CMP (Автодополнение и ТАБ)
-- ==============================================================================
local cmp = require('cmp')
local luasnip = require('luasnip')

-- Автоскобки после выбора функции
cmp.event:on('confirm_done', require('nvim-autopairs.completion.cmp').on_confirm_done())

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = {
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    -- Жесткая логика ТАБА
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'luasnip' }, { name = 'path' } }, { { name = 'buffer' } })
})

-- ==============================================================================
-- 5. ОТЛАДКА (DAP) И ГОРЯЧИЕ КЛАВИШИ
-- ==============================================================================
require('dap-python').setup('python')
local dap = require('dap')

-- Настройка GDB для C и Pascal
dap.adapters.gdb = { type = "executable", command = "gdb", name = "gdb" }
dap.configurations.c = {
  { name = "Launch", type = "gdb", request = "launch", program = function() return vim.fn.input('Path: ', vim.fn.getcwd() .. '/', 'file') end, cwd = "${workspaceFolder}" }
}
dap.configurations.pascal = dap.configurations.c

-- КЛАВИШИ
vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>')
vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files)
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').find_files)
vim.keymap.set('n', '<F6>', ':w<CR>:!fpc % && ./%:r<CR>') -- Pascal
vim.keymap.set('n', '<F5>', function() dap.continue() end)
vim.keymap.set('n', '<F10>', function() dap.step_over() end)
vim.keymap.set('n', '<F11>', function() dap.step_into() end)
vim.keymap.set('n', '<leader>b', function() dap.toggle_breakpoint() end)
