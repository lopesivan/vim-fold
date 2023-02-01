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

if &cp || exists("g:loaded_cpp_fold")
    finish
endif

let g:loaded_cpp_fold = "v01"
let s:keepcpo         = &cpo
set cpo&vim

" ----------------------------------------------------------------------------

function FoldText()

    let StartFoldLine = substitute(getline(v:foldstart), '^\s*', '', 'g')
    let EndFoldLine   = substitute(getline(v:foldend), '^\s*', '', 'g')

    " return indent of before line.
    let ind           = indent(prevnonblank(v:foldstart))

    " range of fold.
    let nLines        = v:foldend - v:foldstart + 1

    " format fold.
    let fmtFold       = StartFoldLine . '..' . EndFoldLine


    return repeat(' ', ind) . fmtFold

endfunction


" ----------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo

" vim: ts=8
