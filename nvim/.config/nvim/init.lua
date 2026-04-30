-- ==============================================================================
-- БЛОК 1: Инициализация пакетного менеджера (Lazy)
-- ==============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ==============================================================================
-- БЛОК 2: Базовые настройки редактора
-- ==============================================================================
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true

-- ==============================================================================
-- БЛОК 3: Установка плагинов
-- ==============================================================================
require("lazy").setup({
    -- 3.1 Внешний вид (Kanagawa с полной прозрачностью)
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        transparent = true, -- Сохраняем прозрачность терминала
        theme = "wave",     -- Основной современный профиль
      })
      vim.cmd("colorscheme kanagawa")
      
      -- Принудительно убираем фон у колонки с номерами строк
      vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
      vim.api.nvim_set_hl(0, "LineNrAbove", { bg = "none" })
      vim.api.nvim_set_hl(0, "LineNrBelow", { bg = "none" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
    end
  },
    -- 3.2 Файловое дерево и Поиск (Telescope)
  { 
    "nvim-neo-tree/neo-tree.nvim", 
    branch = "v3.x", 
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" } 
  },
  { 
    "nvim-telescope/telescope.nvim", 
    tag = "0.1.5", 
    dependencies = { "nvim-lua/plenary.nvim" } 
  },

  -- 3.3 Подсветка синтаксиса (Treesitter)
  { 
    "nvim-treesitter/nvim-treesitter", 
    build = ":TSUpdate", 
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "python", "pascal", "lua", "c", "kotlin" },
        highlight = { enable = true },
      })
    end
  },

  -- 3.4 Управление серверами (Mason)
  { "williamboman/mason.nvim", config = true },

  -- 3.5 Автодополнение и интеграция LSP (включая Luasnip)
  { 
    "hrsh7th/nvim-cmp", 
    dependencies = { 
      "hrsh7th/cmp-nvim-lsp", 
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip", 
      "saadparwaiz1/cmp_luasnip" 
    } 
  },

  -- 3.6 Отладчик (DAP)
  { 
    "mfussenegger/nvim-dap", 
    dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" } 
  },
  { "mfussenegger/nvim-dap-python" },
})

-- ==============================================================================
-- БЛОК 4: Автодополнение и LSP (Новый API Neovim)
-- ==============================================================================
local cmp = require('cmp')
local luasnip = require('luasnip')

-- Настройка движка автодополнения
cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
  })
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Инициализация серверов
local servers = { "pyright", "pasls", "clangd", "kotlin_language_server" }
for _, server in ipairs(servers) do
    vim.lsp.config(server, {
        capabilities = capabilities,
    })
    vim.lsp.enable(server)
end

-- Автоматические проверки (Diagnostics)
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
})

-- ==============================================================================
-- БЛОК 5: Настройка Отладчика (DAP)
-- ==============================================================================
local dap = require('dap')

-- Настройка DAP для Kotlin
dap.adapters.kotlin = {
    type = "executable",
    command = "kotlin-debug-adapter",
    args = {}
}

dap.configurations.kotlin = {
    {
        type = "kotlin",
        request = "launch",
        name = "Launch Kotlin Program",
        mainClass = function()
            return vim.fn.input('Main class: ')
        end,
        projectRoot = "${workspaceFolder}",
    }
}

-- Инициализация DAP для Python
require('dap-python').setup('python')

-- Настройка DAP для C
dap.adapters.gdb = {
    type = "executable",
    command = "gdb",
    name = "gdb"
}

dap.configurations.c = {
    {
        name = "Launch C Program",
        type = "gdb",
        request = "launch",
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = "${workspaceFolder}",
    }
}

-- ==============================================================================
-- БЛОК 6: Горячие клавиши
-- ==============================================================================
local builtin = require('telescope.builtin')

-- Интерфейс
vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle Neo-tree' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })

-- Компиляция и запуск
vim.keymap.set('n', '<F6>', ':w<CR>:!fpc % && ./%:r<CR>', { desc = 'Run Pascal' })

-- Управление отладкой
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'DAP: Start/Continue' })
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'DAP: Step Over' })
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end, { desc = 'DAP: Step Into' })
vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'DAP: Toggle Breakpoint' })
