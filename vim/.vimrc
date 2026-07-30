set nocompatible
filetype plugin indent on
syntax on

" UI
set number
set cursorline
set showmatch
set termguicolors
set background=dark
colorscheme codedark

" Tabs/indentation
set expandtab
set shiftwidth=2
set tabstop=2
set smartindent

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Behavior
set mouse=a
if has('clipboard')
  if has('unnamedplus')
    set clipboard=unnamed,unnamedplus
  else
    set clipboard=unnamed
  endif
endif
set updatetime=300
