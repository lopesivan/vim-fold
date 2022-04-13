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

if &cp || exists("g:loaded_c_ansi_fold")
    finish
endif

let g:loaded_c_ansi_fold = "v01"
let s:keepcpo            = &cpo
set cpo&vim

" ----------------------------------------------------------------------------

function CansiFoldText()

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

function GetCansiFoldExpr()

    let Line = getline(v:lnum)

    " Ignore blank lines
    if line =~ '^\s*$'
        return "="
    endif

    " Ignore Commnet inline
    if (Line =~ '/\*.*') && (Line =~ '.*\*/')
        return "="
    endif

    " match cBlock
    if Line =~ '\(/\*.*\|{.*\)'
        return "a1"
    endif

    if Line =~ '\(.*\*/\|.*}\)'
        return "s1"
    endif

    return '='
endfunction

" ----------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo

" vim: ts=8
