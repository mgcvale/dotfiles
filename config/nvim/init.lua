vim.o.number = true
vim.o.relativenumber = true

-- Enable syntax highlighting
vim.cmd('syntax on')

-- Set a color scheme

-- Install packer if not installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end
ensure_packer()

-- Packer setup
require('packer').startup(function()
  use 'wbthomason/packer.nvim' -- Packer manages itself
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  use 'morhetz/gruvbox'
  use 'folke/tokyonight.nvim'
  use 'arcticicestudio/nord-vim'
  use 'altercation/vim-colors-solarized'
  use 'catppuccin/nvim'
  use 'bluz71/vim-nightfly-colors'
end)

-- Treesitter configuration for C
require'nvim-treesitter.configs'.setup {
  ensure_installed = {"c"},
  highlight = {
    enable = true,
  },
}

cmd('colorscheme nightfly')
