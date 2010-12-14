" StatusLineHighlight.vim: summary
"
" DEPENDENCIES:
"
" Copyright: (C) 2010 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	15-Dec-2010	file creation

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_StatusLineHighlight') || (v:version < 700)
    finish
endif
let g:loaded_StatusLineHighlight = 1

function! s:SetHighlight( name )
    let &l:stl = '%#StatusLine' . a:name . '#' . &g:stl
    return
    if &g:stl ==# &l:stl
	let &l:stl='%#Conceal#' . &g:stl
    else
	let &l:stl='%#Conceal#' . &l:stl
    endif
endfunction
function! s:ClearHighlight()
    setlocal stl&
endfunction
function! s:StatuslineHighlight( isEnter )
    let l:notCurrent = (a:isEnter ? '' : 'NC')
    if ! &modifiable
	call s:SetHighlight('Readonly' . l:notCurrent)
    elseif &readonly
	call s:SetHighlight('Readonly' . l:notCurrent)
    else
	call s:ClearHighlight()
    endif
    return ''
endfunction

augroup StatuslineHighlight
    autocmd!
    autocmd BufWinEnter,WinEnter * call <SID>StatuslineHighlight(1)
    autocmd WinLeave * call <SID>StatuslineHighlight(0)
augroup END

hi def StatusLineReadonly   gui=bold,reverse guifg=DarkGrey
hi def StatusLineReadonlyNC gui=reverse guifg=DarkGrey

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
