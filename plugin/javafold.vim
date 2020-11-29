" $Id$
" Name Of File: |;n|
"
"  Description: Vim plugin
"
"       Author: Ivan Carlos S. Lopes <lopesivan (at) poli (dot) com (dot) br>
"   Maintainer: Ivan Carlos S. Lopes <lopesivan (at) poli (dot) com (dot) br>
"
"  Last Change: $Date:$
"      Version: $Revision:$
"
"    Copyright: This script is released under the Vim License.
"

if &cp || exists("g:loaded_java_fold")
	finish
endif

let g:loaded_java_fold = "v01"
let s:keepcpo            = &cpo
set cpo&vim

" ----------------------------------------------------------------------------

function JavaFoldText()

	let StartFoldLine = substitute(getline(v:foldstart), '^\s*', '', 'g')
	let EndFoldLine   = substitute(getline(v:foldend), '^\s*', '', 'g')

	" return indent of before line.
	let ind           = indent(prevnonblank(v:foldstart))

	" range of fold.
	let nLines        = v:foldend - v:foldstart + 1

	" format fold.
	let fmtFold       = StartFoldLine . '..' . EndFoldLine

	if (StartFoldLine[0:1] == '/*') && (EndFoldLine[-2:] == '*/')

		return repeat(' ', ind).StartFoldLine[0:1].'..'.EndFoldLine[-2:]

	else

		return repeat(' ', ind) . fmtFold

	endif

endfunction

function GetJavaFoldExpr()

	let Line = getline(v:lnum)

	" Ignore blank lines
	if line =~ '{}'
		return "="
	endif

	" Ignore blank lines
	if line =~ '^\s*$'
		return "="
	endif

	" Ignore Commnet inline
	if (Line =~ '/\*.*') && (Line =~ '.*\*/')
		return "="
	endif

	" match cBlock
	if Line =~ '\(/\*.*\|^[^{]*{[^}]*$\)'
		return "a1"
	endif

	if Line =~ '\(.*\*/\|^[^{]*}[^}]*$\)'
		return "s1"
	endif

	return '='
endfunction

" ----------------------------------------------------------------------------

" Function: s:IsACommentLine(lnum)
function! s:IsACommentLine(lnum, or_blank)
	let line = getline(a:lnum)
	if line =~ '^\s*//'. (a:or_blank ? '\|^\s*$' : '')
		" C++ comment line / empty line => continue
		return 1
	elseif line =~ '\S.*\(//\|/\*.\+\*/\)'
		" Not a comment line => break
		return 0
	else
		let id = synIDattr(synID(a:lnum, strlen(line)-1, 0), 'name')
		return id =~? 'comment\|doxygen'
	endif
endfunction

" Function: s:PrevNonComment(lnum)
" Comments => ignore them:
" the fold level is determined by the code that follows
function! s:PrevNonComment(lnum, or_blank)
	let lnum = a:lnum
	while (lnum > 0) && s:IsACommentLine(lnum, a:or_blank)
		let lnum = lnum - 1
	endwhile
	return lnum
endfunction

" Function: s:NextNonCommentNonBlank(lnum)
" Comments => ignore them:
" the fold level is determined by the code that follows
function! s:NextNonCommentNonBlank(lnum, or_blank)
	let lnum = a:lnum
	let lastline = line('$')
	while (lnum <= lastline) && s:IsACommentLine(lnum, a:or_blank)
		let lnum = lnum + 1
	endwhile
	return lnum
endfunction

" Function: CFold(lnum)
fun! CFold(lnum)
	let lnum = s:NextNonCommentNonBlank(a:lnum, b:fold_blank)
	let last = line('$')
	if lnum > last
		return -1
	endif

	" Fold level of the previous line
	if a:lnum > 1
		let prev_lvl = foldlevel(a:lnum-1)
		" Test if prec line was special
		let pline = getline(a:lnum - 1)
		let pline = substitute(pline, '{[^}]*}', '', 'g')
		let pline = substitute(pline, '"\%(\\"\|[^"]\)*"'    , '', 'g')
		let pline = substitute(pline, "'\\%(\\\\'\\|[^']\\)*'", '', 'g')
		let pline = substitute(pline, '\/\/.*$', '', 'g')

		if s:IsACommentLine(a:lnum-1, b:fold_blank)
			let was = 'nothing'
		elseif pline =~ '^\s*#'
			let was = 'precomp'
		elseif pline =~ '}[ \t;]*$'
			let was = 'closing'
		elseif pline =~ '^\s*\(default\|case\s*\k\+\)\s*:\s*$'
			let was = 'case'
		elseif pline =~ '[;:]\s*$' || pline =~ '^\s*$'
			let was = 'instr'
		elseif pline =~ '{\s*$'
			let was = 'opening'
		else
			let was = 'nothing'
		endif
	else
		let prev_lvl = 1
		let was = 'beginning'
	endif
	let g:was = was

	if was == 'nothing'
		return '='
		" return prev_lvl+1
	endif

	while lnum <= last
		let line = getline(lnum)
		if line =~ '^\s*#'
			" preprocessor line
			return '='
		endif
		" Strip one-line blocks of code
		let line = substitute(line, '{[^}]*}', '', 'g')
		" Strip strings and //-comments
		let line = substitute(line, '"\(\\"\|[^"]\)*"'    , '', 'g')
		let line = substitute(line, "'\\(\\\\'\\|[^']\\)*'", '', 'g')
		let line = substitute(line, '\/\/.*$', '', 'g')

		if line =~ '}[ \t;]*$'
			" let ind = (indent(lnum) / &sw)
			" exe 'return "<'.ind.'"'
			if lnum == a:lnum
				" let ind = (indent(lnum) / &sw)  + 1
				" exe 'return "<'.ind.'"'
				" exe 'return "<'.(prev_lvl).'"'
				let p = searchpair('{', '', '}.*$', 'bn',
					\  "synIDattr(synID(line('.'),col('.'), 0), 'name') "
					\ ."=~? 'string\\|comment\\|doxygen'")
				if (getline(p) =~ 'switch\s*(.*)\s*{')
					\ || (getline(s:PrevNonComment(p-1, b:fold_blank)) =~ 'switch\s*(.*)\s*{')
					return 's2'
				else
					return 's1'
				endif

			else
				return '='
			endif
		elseif line =~ '^\s*\(default\|case\s\+.\+\)\s*:\s*$'
			" cases for 'switch' statement
			" => new folder of fold level 'indent()+1'
			" return 'a1'
			" let ind = (indent(lnum) / &sw) + 1
			" exe 'return ">'.ind.'"'
			" return 'a1'
			exe 'return ">'.prev_lvl.'"'
		elseif line =~ '[;:]\s*$' || line =~ '^\s*$'
			" lines ending with a ';', empty lines or labels => keep folding level
			" auch: return -1
			" oder: return '='
			" return ind
			return '='
		elseif line =~ '{\s*$'
			" return 'a1'
			" let ind = (indent(lnum) / &sw) + 1
			if b:show_if_and_else && line =~ '^\s*}'
				" => new folder of fold level 'ind'
				" exe 'return ">'.ind.'"'
				" return 'a1'
				exe 'return ">'.(prev_lvl).'"'
			else
				" => folder of fold level 'indent()' (not necesseraly a new one)
				" exe 'return '.ind
				" exe 'return "'.(prev_lvl+1).'"'
				return 'a1'
				exe 'return "'.(prev_lvl+1).'"'
			endif
		endif
		let lnum = s:NextNonCommentNonBlank(lnum + 1, b:fold_blank)
	endwhile
endfun

" Function: CFold0(lnum)
fun! CFold0(lnum)
	let lnum = s:NextNonCommentNonBlank(a:lnum, b:fold_blank)
	let last = line('$')
	if lnum > last
		return -1
	endif

	while lnum <= last
		let line = getline(lnum)
		if line =~ '^\s*#'
			" preprocessor line
			" return '='
			return foldlevel(a:lnum-1)
		endif
		" Strip one-line blocs of code
		let line = substitute(line, '{[^}]*}', '', 'g')
		" Strip strings and //-comments
		let pline = substitute(pline, '"\%(\\"\|[^"]\)*"'    , '', 'g')
		let pline = substitute(pline, "'\\%(\\\\'\\|[^']\\)*'", '', 'g')
		" let line = substitute(line, '"[^"]*"', '', 'g')
		" let line = substitute(line, "'[^']*'", '', 'g')
		let line = substitute(line, '\/\/.*$', '', 'g')

		if line =~ '}[ \t;]*$'
			" let ind = (indent(lnum) / &sw)
			" exe 'return "<'.ind.'"'
			if lnum == a:lnum
				let ind = (indent(lnum) / &sw)  + 1
				" let ind = foldlevel(a:lnum - 1) " if not a comment...
				let p = searchpair('{', '', '}.*$', 'bn',
					\  "synIDattr(synID(line('.'),col('.'), 0), 'name') "
					\ ."=~? 'string\\|comment\\|doxygen'")
				if (getline(p) =~ 'switch\s*(.*)\s*{')
					\ || (getline(s:PrevNonComment(p-1, b:fold_blank)) =~ 'switch\s*(.*)\s*{')
					" exe 'return "<'.(ind-1).'"'
					return '<'.(ind-1)
				else
					" exe 'return "<'.ind.'"'
					return '<'.ind
				endif
			else
				" return '='
				return foldlevel(a:lnum-1)
			endif
		elseif line =~ '^\s*\(default\|case\s\+.\+\)\s*:\s*$'
			" cases for 'switch' statement
			" => new folder of fold level 'indent()+1'
			" return 'a1'
			let ind = (indent(lnum) / &sw) + 1
			exe 'return ">'.ind.'"'
		elseif line =~ '[;:]\s*$' || line =~ '^\s*$'
			" lines ending with a ';', empty lines or labels => keep folding level
			" auch: return -1
			" oder: return '='
			" return ind
			return '='
		elseif line =~ '{\s*$'
			" return 'a1'
			let ind = (indent(lnum) / &sw) + 1
			if b:show_if_and_else && line =~ '^\s*}'
				" => new folder of fold level 'ind'
				exe 'return ">'.ind.'"'
			else
				" => folder of fold level 'indent()' (not necesseraly a new one)
				exe 'return '.ind
			endif
		endif
		let lnum = s:NextNonCommentNonBlank(lnum + 1, b:fold_blank)
	endwhile
endfun

" Function: s:Build_ts()
function! s:Build_ts()
	if !exists('s:ts_d') || (s:ts_d != &ts)
		let s:ts = ''
		let i = &ts
		while i>0
			let s:ts = s:ts . ' '
			let i = i - 1
		endwhile
		let s:ts_d = &ts
	endif
	return s:ts
endfunction

" Function: CFoldText()
fun! CFoldText()
	let ts = s:Build_ts()
	let lnum = v:foldstart
	let lastline = line('$')
	" if lastline - lnum > 5 " use at most 5 lines
	" let lastline = lnum + 5
	" endif
	let line = ''
	let lnum = s:NextNonCommentNonBlank(lnum, b:fold_blank)

	" Loop for all the lines in the fold
	while lnum <= lastline
		let current = getline(lnum)
		let current = substitute(current, '{\{3}\d\=.*$', '', 'g')
		let current = substitute(current, '/\*.*\*/', '', 'g')
		if current =~ '[^:]:[^:]'
			" class XXX : ancestor
			let current = substitute(current, '\([^:]\):[^:].*$', '\1', 'g')
			let break = 1
		elseif current =~ '{\s*$'
			" '  } else {'
			let current = substitute(current, '^\(\s*\)}\s*', '\1', 'g')
			let current = substitute(current, '{\s*$', '', 'g')
			let break = 1
		else
			let break = 0
		endif
		if '' == line
			" preserve indention: substitute leading tabs by spaces
			let leading_tabs = strlen(substitute(current, "[^\t].*$", '', 'g'))
			if leading_tabs > 0
				let leading = ''
				let i = leading_tabs
				while i > 0
					let leading = leading . ts
					let i = i - 1
				endwhile
				" let current = leading . strpart(current, leading_tabs, 999999)
				let current = leading . strpart(current, leading_tabs)
			endif
		else
			" remove leading and trailing white spaces
			let current = matchstr(current, '^\s*\zs.\{-}\ze\s*$')
			" let current = substitute(current, '^\s*', '', 'g')
		endif
		if '' != line && current !~ '^\s*$'
			" add a separator
			let line = line . ' '
		endif
		let line = line . current
		if break
			break
		endif
		" Goto next line
		let lnum = s:NextNonCommentNonBlank(lnum + 1, b:fold_blank)
	endwhile

	" Strip template parameters
	if strlen(line) > (winwidth(winnr()) - &foldcolumn)
		\ && !b:show_template_arguments && line =~ '\s*template\s*<'
		let c0 = stridx(line, '<') + 1 | let lvl = 1
		let c = c0
		while c > 0
			let c = match(line, '[<>]', c+1)
			if     line[c] == '<'
				let lvl = lvl + 1
			elseif line[c] == '>'
				if lvl == 1 | break | endif
				let lvl = lvl - 1
			endif
		endwhile
		let line = strpart(line, 0, c0) . '...' . strpart(line, c)
	endif

	" Strip whatever follows "case xxx:" and "default:"
	let line = substitute(line,
		\ '^\(\s*\%(case\s\+.\{-}[^:]:\_[^:]\|default\s*:\)\).*', '\1', 'g')

	" Return the result
	return substitute(line, "\t", ' ', 'g')
	" let lines = v:folddashes . '[' . (v:foldend - v:foldstart + 1) . ']'
	" let len = 10 - strlen(lines)
	" while len > 0
	"     let lines = lines . ' '
	"     let len = len - 1
	" endwhile
	" return lines . line
endfun

" ----------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo

" vim: ts=8
