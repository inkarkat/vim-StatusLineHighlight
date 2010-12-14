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
    let l:statuslineWithHighlight = '%#StatusLine' . a:name . '#' . &g:stl

    if &l:stl ==# l:statuslineWithHighlight
	" The highlight is already set; nothing to do. 
	return
    endif

    if empty(&l:stl)
	" There's no local setting so far; simply customize the global setting
	" with the passed highlight group. 
	let &l:stl = l:statuslineWithHighlight
    else
	" There exists a local setting; this may be one of our highlight
	" customizations with a different highlight group, or an actual special
	" statusline set by either the user or a filetype plugin. 
echomsg '*** old: ' . strpart(&l:stl, 0, 25) . ' new: ' strpart(l:statuslineWithHighlight, 0, 25)
	if ! exists('w:save_statusline')
	    let w:save_statusline = &l:stl
	endif
	let &l:stl = '%#StatusLine' . a:name . '#' . substitute(&l:stl, '^%#StatusLine\w\+#', '', '')
    endif
endfunction
function! s:ClearHighlight()
    if &l:stl !~# '^%#StatusLine\w\+#'
	return
    endif

    if exists('w:save_statusline')
	let &l:stl = w:save_statusline
	unlet w:save_statusline
    else
	setlocal stl&
    endif
endfunction
function! s:StatuslineHighlight( isEnter )
    let l:notCurrent = (a:isEnter ? '' : 'NC')
    if ! &modifiable
	call s:SetHighlight('Unmodifiable' . l:notCurrent)
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
hi def StatusLineUnmodifiable   gui=bold,reverse guifg=DarkRed
hi def StatusLineUnmodifiableNC gui=reverse guifg=DarkRed

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
