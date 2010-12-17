" StatusLineHighlight.vim: summary
"
"   Using different colors for the status line is trickier than it seems: Though
"   the 'statusline' setting supports inline expressions via %{expr}, the
"   returned text is taken as-is; highlight items %#hlgroup# and #* are not
"   evaluated, only printed as text. Evaluation does happen when one %!expr is
"   used, but the expression seems to be evaluated only once for a complete
"   screen redraw cycle, not for each individual status line, so one cannot use
"   it to set different highlightings for different status lines. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2010 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	002	16-Dec-2010	Added highlight groups for more than just
"				readonly. 
"				Added autocmds to better capture buffer
"				modification: InsertEnter (followed by fire-once
"				CursorMovedI) and BufWritePost. 
"	001	15-Dec-2010	file creation

" Avoid installing twice, when in unsupported Vim version, or there are no
" colors. 
if exists('g:loaded_StatusLineHighlight') || (v:version < 700) || (! has('gui_running') && &t_Co <= 2)
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
	" customizations with a different highlight group, or an actual
	" window-local statusline set by either the user or a filetype plugin. 
"****D echomsg '*** old: ' . strpart(&l:stl, 0, 25) . ' new: ' strpart(l:statuslineWithHighlight, 0, 25)
	let l:statuslineWithoutHighlight = substitute(&l:stl, '^%#StatusLine\w\+#', '', '')
	if &l:stl ==# l:statuslineWithoutHighlight
	    " There actually was an actual window-local statusline. Save it so
	    " that it can be restored instead of overwriting it with the global
	    " statusline. 
	    let w:save_statusline = l:statuslineWithoutHighlight
	endif

	let &l:stl = '%#StatusLine' . a:name . '#' .  l:statuslineWithoutHighlight
    endif
endfunction
function! s:ClearHighlight()
    if &l:stl !~# '^%#StatusLine\w\+#'
	" There was none of our highlight customizations. 
	return
    endif

    if exists('w:save_statusline')
	" Restore the saved window-local setting. 
	let &l:stl = w:save_statusline
	unlet w:save_statusline
    else
	" Restore the global setting. 
	setlocal stl&
    endif
endfunction
function! s:StatusLineHighlight( isEnter )
    let l:notCurrent = (a:isEnter ? '' : 'NC')
    if &l:previewwindow
	call s:SetHighlight('Preview' . l:notCurrent)
    elseif &l:modified
	call s:SetHighlight('Modified' . l:notCurrent)
    elseif ! (&l:buftype ==# '' || &l:buftype ==# 'acwrite')
	call s:SetHighlight('Special' . l:notCurrent)
    elseif ! &l:modifiable
	call s:SetHighlight('Unmodifiable' . l:notCurrent)
    elseif &l:readonly
	call s:SetHighlight('Readonly' . l:notCurrent)
    else
	call s:ClearHighlight()
    endif
    return ''
endfunction

function! s:StatusLineGetModification()
    augroup StatusLineHighlightModification
	autocmd!
	autocmd CursorMovedI * call <SID>StatusLineHighlight(1) | autocmd! StatusLineHighlightModification
    augroup END
endfunction

augroup StatusLineHighlight
    autocmd!
    autocmd BufWinEnter,WinEnter,CursorHold,CursorHoldI,BufWritePost * call <SID>StatusLineHighlight(1)
    autocmd WinLeave * call <SID>StatusLineHighlight(0)
    autocmd InsertEnter * if ! &l:modified | call <SID>StatusLineGetModification() | endif
augroup END


hi def StatusLineModified           term=bold,reverse cterm=bold,reverse ctermbg=DarkRed  gui=bold,reverse guifg=DarkRed
hi def StatusLineModifiedNC         term=reverse      cterm=reverse      ctermbg=DarkRed  gui=reverse      guifg=DarkRed
hi def StatusLinePreview            term=bold,reverse cterm=bold,reverse ctermbg=Blue     gui=bold,reverse guifg=Blue
hi def StatusLinePreviewNC          term=reverse      cterm=reverse      ctermbg=Blue     gui=reverse      guifg=Blue
hi def StatusLineReadonly           term=bold,reverse cterm=bold,reverse ctermbg=Grey     gui=bold,reverse guifg=DarkGrey
hi def StatusLineReadonlyNC         term=reverse      cterm=reverse      ctermbg=Grey     gui=reverse      guifg=DarkGrey
hi def StatusLineSpecial            term=bold,reverse cterm=bold,reverse ctermbg=DarkBlue gui=bold,reverse guifg=DarkBlue
hi def StatusLineSpecialNC          term=reverse      cterm=reverse      ctermbg=DarkBlue gui=reverse      guifg=DarkBlue
hi def StatusLineUnmodifiable       term=bold,reverse cterm=bold,reverse ctermbg=Grey     gui=bold,reverse guifg=Grey
hi def StatusLineUnmodifiableNC     term=reverse      cterm=reverse      ctermbg=Grey     gui=reverse      guifg=Grey

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
