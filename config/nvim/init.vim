lua << EOF
-- setup plugins
require('packer').startup(function(use)
    use 'Tsuzat/NeoSolarized.nvim'
    use 'wbthomason/packer.nvim' 
    use 'neovim/nvim-lspconfig'
    use "EdenEast/nightfox.nvim"
    use { 'AlphaTechnolog/pywal.nvim', as = 'pywal' }
    use {
        'nvim-treesitter/nvim-treesitter'
    }
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.8',
        requires = { {'nvim-lua/plenary.nvim'} }
    }
    use {
        'nvim-tree/nvim-tree.lua',
        requires = 'nvim-tree/nvim-web-devicons',  -- Optional icons plugin
        config = function()
        require'nvim-tree'.setup {
            respect_buf_cwd = true,       -- Sync tree root with current working directory
            update_focused_file = {
                enable = true,
                update_cwd = true,          -- Update tree root to match current buffer's directory
            },
            view = {
                width = 30,                 -- Set sidebar width
                side = 'right',              -- Position the sidebar on the left
            },
        }
    end
    }
end)

EOF

" Basic settings
let mapleader = " "
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set signcolumn=no

" Theming
autocmd FileType c colorscheme NeoSolarized
autocmd FileType h colorscheme NeoSolarized
autocmd FileType txt colorscheme NeoSolarized

lua << EOF
local ok_status, NeoSolarized = pcall(require, "NeoSolarized")

if not ok_status then
  return
end

-- Default Setting for NeoSolarized

NeoSolarized.setup {
  style = "dark", -- "dark" or "light"
  transparent = false, -- true/false; Enable this to disable setting the background color
  terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
  enable_italics = true, -- Italics for different hightlight groups (eg. Statement, Condition, Comment, Include, etc.)
  styles = {
    -- Style to be applied to different syntax groups
    comments = { italic = true },
    keywords = { italic = true },
    functions = { bold = true },
    variables = {},
    string = { italic = true },
    underline = true, -- true/false; for global underline
    undercurl = true, -- true/false; for global undercurl
  },
  -- Add specific hightlight groups
  on_highlights = function(highlights, colors) 
    -- highlights.Include.fg = colors.red -- Using `red` foreground for Includes
  end, 
}
EOF

"colorscheme pywal
let g:wal_mode = 'default'
silent! !wal -R

" Set the background and ensure it's not transparent
highlight Normal ctermbg=NONE guibg=NONE
highlight Normal guibg=bg  " Use the bg color from the pywal theme



" LSP
"
lua << EOF
require'lspconfig'.clangd.setup {
    on_attach = function(client, bufnr)
    end,
    flags = {
        debounce_text_changes = 30,
    },
    cmd = {"clangd", "--background-index" },
}

vim.diagnostic.config({
    update_in_insert = true,
    virtual_text = true,
    underline = true,      
    severity_sort = true,
})

vim.api.nvim_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', { noremap = true, silent = true })

EOF

" Telescope configuration
"
nnoremap <leader>ff <cmd>Telescope find_files<cr>


" Tree configuration
"
lua << EOF
vim.api.nvim_set_keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
EOF
