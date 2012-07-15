nmap <leader>. :TagbarToggle<CR>

" Set the TagBar width a bit smaller to not cover the default code width
let g:tagbar_width = 35

" Give focus to the TagBar on open - useful for quickly navigating between methods
let g:tagbar_autofocus = 1

" Turn off automatic sorting
let g:tagbar_sort = 0

" Markdown language configuration
let g:tagbar_type_markdown = {
  \ 'ctagstype' : 'Markdown',
  \ 'kinds'     : [
    \ 'h:headers'
  \ ]
\ }
