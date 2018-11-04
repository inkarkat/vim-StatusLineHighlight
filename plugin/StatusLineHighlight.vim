" StatusLineHighlight.vim: Change statusline color depending on buffer state. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2010-2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.01.006	01-Jul-2011	Avoid losing the statusline highlightings on
"				:colorscheme commands. 
"   1.00.005	27-Dec-2010	Added check and emulation for empty &g:stl (the
"				default), so that this also works for a vanilla,
"				uncustomized Vim. 
"				Added CmdwinEnter event to properly highlight
"				the command window as "special". 
"	004	21-Dec-2010	Corrected cterm highlighting. cterm=reverse
"				doesn't work in the Windows console. Added a
"				note about this and possible workarounds. 
"	003	18-Dec-2010	Now detecting buffer modification also after
"				moving around while in insert mode. 
"				Shuffled blocks around in the script. 
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

"- default highlightings ------------------------------------------------------
" You may define your own colors in your vimrc file, in the form as below: 
"
" Note: Some terminals (the Windows console) cannot mix cterm=reverse with
" coloring (cp. :help highlight-cterm). Override the default settings if this
" doesn't work for you; e.g. you could emulate the inversion by specifying the
" background color as the foreground color. The Windows console also doesn't
" support cterm=bold, so you may already have a special case for it, anyway. 
function! s:DefaultHighlightings()
    highlight def StatusLineModified           term=bold,reverse cterm=bold,reverse ctermfg=DarkRed  gui=bold,reverse guifg=DarkRed
    highlight def StatusLineModifiedNC         term=reverse      cterm=reverse      ctermfg=DarkRed  gui=reverse      guifg=DarkRed
    highlight def StatusLinePreview            term=bold,reverse cterm=bold,reverse ctermfg=Blue     gui=bold,reverse guifg=Blue
    highlight def StatusLinePreviewNC          term=reverse      cterm=reverse      ctermfg=Blue     gui=reverse      guifg=Blue
    highlight def StatusLineReadonly           term=bold,reverse cterm=bold,reverse ctermfg=Grey     gui=bold,reverse guifg=DarkGrey
    highlight def StatusLineReadonlyNC         term=reverse      cterm=reverse      ctermfg=Grey     gui=reverse      guifg=DarkGrey
    highlight def StatusLineSpecial            term=bold,reverse cterm=bold,reverse ctermfg=DarkBlue gui=bold,reverse guifg=DarkBlue
    highlight def StatusLineSpecialNC          term=reverse      cterm=reverse      ctermfg=DarkBlue gui=reverse      guifg=DarkBlue
    highlight def StatusLineUnmodifiable       term=bold,reverse cterm=bold,reverse ctermfg=Grey     gui=bold,reverse guifg=Grey
    highlight def StatusLineUnmodifiableNC     term=reverse      cterm=reverse      ctermfg=Grey     gui=reverse      guifg=Grey
endfunction
call s:DefaultHighlightings()


"- functions ------------------------------------------------------------------
function! s:DefaultStatusline()
    " With the prepended highlight group, an empty 'statusline' setting has a
    " different meaning: the status line would be colored, but completely empty.
    " Thus, we have to emulate Vim's default status line here. 
    return '%<%f %h%m%r' . (&ruler ? '%=%-14.(%l,%c%V%) %P' : '')
endfunction
function! s:SetHighlight( name )
    let l:statuslineWithHighlight = '%#StatusLine' . a:name . '#' . (empty(&g:stl) ? s:DefaultStatusline() : &g:stl)

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


"- autocmds -------------------------------------------------------------------
function! s:StatusLineGetModification()
    augroup StatusLineHighlightModification
	autocmd!
	autocmd CursorMovedI * if &l:modified | call <SID>StatusLineHighlight(1) | execute 'autocmd! StatusLineHighlightModification' | endif
    augroup END
endfunction

augroup StatusLineHighlight
    autocmd!
    autocmd BufWinEnter,WinEnter,CmdwinEnter,CursorHold,CursorHoldI,BufWritePost * call <SID>StatusLineHighlight(1)
    autocmd WinLeave * call <SID>StatusLineHighlight(0)
    autocmd InsertEnter * if ! &l:modified | call <SID>StatusLineGetModification() | endif
    autocmd ColorScheme * call <SID>DefaultHighlightings()
augroup END

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
