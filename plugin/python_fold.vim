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

if &cp || exists("g:loaded_python_fold")
  finish
endif

let g:loaded_python_fold = "v01"
let s:keepcpo            = &cpo
set cpo&vim

" ----------------------------------------------------------------------------

function PythonFoldText()
  let StartFoldLine = substitute(getline(v:foldstart), '^\s*', '', 'g')
  let EndFoldLine   = substitute(getline(v:foldend), '^\s*', '', 'g')

  " return indent of before line.
  let ind           = indent(prevnonblank(v:foldstart))

  " range of fold.
  let nLines        = v:foldend - v:foldstart + 1

  " format fold.
  let fmtFold       = StartFoldLine . '..'
  "let fmtFold       = StartFoldLine . '..' . EndFoldLine

  if (StartFoldLine[0:1] == '/*') && (EndFoldLine[-2:] == '*/')

    return repeat(' ', ind).StartFoldLine[0:1].'..'.EndFoldLine[-2:]

  else

    return repeat(' ', ind) . fmtFold

  endif
endfunction

function GetPythonFoldExpr()

  " Determine folding level in Python source
  "
  let line = getline(v:lnum)
  let ind  = indent(v:lnum)

  "TODO: commentei esta linha para permitir linhas em branco
  " " Ignore blank lines
  " if line =~ '^\s*$'
  "   return 0
  " endif

  " Ignore triple quoted strings
  if line =~ "(\"\"\"|''')"
    return "="
  endif

  " Ignore continuation lines
  if line =~ '\\$'
    return '='
  endif

  " Support markers
  if line =~ '{{{'
    return "a1"
  elseif line =~ '}}}'
    return "s1"
  endif

  " Classes and functions get their own folds
  if line =~ '^\s*\(class\|def\|if\|for\)\s'
    return ">" . (ind / &sw + 1)
  endif

  if line =~ '^\s*\(try\)\:'
    return ">" . (ind / &sw + 1)
  endif

  let pnum = prevnonblank(a:lnum - 1)

  if pnum == 0
    " Hit start of file
    return 0
  endif

  " If the previous line has foldlevel zero, and we haven't increased
  " it, we should have foldlevel zero also
  if foldlevel(pnum) == 0
    return 0
  endif

  " The end of a fold is determined through a difference in indentation
  " between this line and the next.
  " So first look for next line
  let nnum = nextnonblank(a:lnum + 1)
  if nnum == 0
    return "="
  endif

  " First I check for some common cases where this algorithm would
  " otherwise fail. (This is all a hack)
  let nline = getline(nnum)
  if nline =~ '^\s*\(except\|else\|elif\)'
    return "="
  endif

  " Python programmers love their readable code, so they're usually
  " going to have blank lines at the ends of functions or classes
  " If the next line isn't blank, we probably don't need to end a fold
  if nnum == a:lnum + 1
    return "="
  endif

  " If next line has less indentation we end a fold.
  " This ends folds that aren't there a lot of the time, and this sometimes
  " confuses vim.  Luckily only rarely.
  let nind = indent(nnum)
  if nind < ind
    return "<" . (nind / &sw + 1)
  endif

  " If none of the above apply, keep the indentation
  return "="

endfunction

function! GetPythonFoldBest()
    " Determine folding level in Python source
    "
    let line = getline(v:lnum - 1)

    " Handle Support markers
    if line =~ '{{{'
        return "a1"
    elseif line =~ '}}}'
        return "s1"
    endif

    " Classes and functions get their own folds
      if line =~ '^\s*\(class\|def\)\s'
    " Verify if the next line is a class or function definition
    " as well
        let imm_nnum = v:lnum + 1
        let nnum = nextnonblank(imm_nnum)
        let nind = indent(nnum)
        let pind = indent(v:lnum - 1)
        if pind >= nind
            let nline = getline(nnum)
            let w:nestinglevel = nind
            return "<" . ((w:nestinglevel + &sw) / &sw)
        endif
        let w:nestinglevel = indent(v:lnum - 1)
        return ">" . ((w:nestinglevel + &sw) / &sw)
    endif

    " If next line has less or equal indentation than the first one,
    " we end a fold.
    let nnonblank = nextnonblank(v:lnum + 1)
    let nextline = getline(nnonblank)
    if (nextline !~ '^#\+.*')
        let nind = indent(nnonblank)
        if nind <= w:nestinglevel
            let w:nestinglevel = nind
            return "<" . ((w:nestinglevel + &sw) / &sw)
        else
            let ind = indent(v:lnum)
            if ind == (w:nestinglevel + &sw)
                if nind < ind
                    let w:nestinglevel = nind
                    return "<" . ((w:nestinglevel + &sw) / &sw)
                endif
            endif
        endif
    endif

    " If none of the above apply, keep the indentation
    return "="
endfunction

" ----------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo

" vim: ts=8
