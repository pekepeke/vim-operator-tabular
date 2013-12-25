let s:save_cpo = &cpo
set cpo&vim

" instance {{{1
let s:base = {
      \ 'name' : 'base',
      \ '_layout' : [],
      \ '_lines': [],
      \ }
let s:debug = 1
let s:logs = []

if s:debug
  command! -nargs=0 TabularDebugLog echo join(s:logs, "\n")
endif

function! s:base.new() "{{{2
  return extend({}, self)
endfunction

function! s:base.log(...) "{{{2
  if s:debug
    call add(s:logs, string(a:000))
  endif
endfunction

function! s:base.preprocess(lines) "{{{2
  let self._lines = copy(a:lines)
  call self.calc(a:lines)
endfunction

function! s:base.calc(lines) "{{{2
  let layout = map(range(0, len(get(a:lines, 0, [])) - 1), '0')
  for line in copy(a:lines)
    let i = 0
    for item in line
      if !exists('layout[i]')
        call add(layout, 0)
      endif
      let vlen = s:strlen(item)
      let llen = get(layout, i, 0)
      if vlen > llen
        let layout[i] = vlen
      endif
      let i = i + 1
    endfor
    " let layout = map(line, 's:strlen(v:val) > get(layout, v:key, 0)')
  endfor
  let self._layout = layout
endfunction

function! s:base.layout() "{{{2
  return copy(self._layout)
endfunction

function! s:base.lines() "{{{2
  return copy(self._lines)
endfunction

function! s:base.fill_items(line) "{{{2
  let layout = self.layout()

  let arr = map(a:line, 'v:val . repeat(" ", get(layout, v:key, 0) - <SID>strlen(v:val))')
  return arr
endfunction

function! s:base.make_separator(sep) "{{{2
  let len = s:strdisplaywidth(a:sep)
  if len <= 0
    let len = 1
  endif
  return map(self.layout(), 'repeat(a:sep, v:val/len)')
endfunction

function! s:base.split_and_trim(s, expr) "{{{2
  let items = split(a:s, a:expr)
  return map(items, 'substitute(v:val, "^\\s*\\|\\s*$", "", "g")')
endfunction

" abstract methods {{{2
function! s:base.render(lines) "{{{3
  call self.preprocess(a:lines)
  return ""
endfunction

function! s:base.restore_from_lines(lines) "{{{3
  return [[]]
endfunction

" main interfaces {{{2
function! s:base.tabularize(motion_wise, reader)
  let [reg_0, lines] = s:read_op(a:motion_wise)
  if empty(lines)
    return
  endif
  let cr = a:reader
  let s = self.render(cr.parse_from_list(lines))
  call s:replace_op(a:motion_wise, s, reg_0)
endfunction

function! s:base.tabularize_tsv(motion_wise) "{{{3
  return self.tabularize(a:motion_wise, csvutil#tsv_reader())
endfunction

function! s:base.tabularize_csv(motion_wise) "{{{3
  return self.tabularize(a:motion_wise, csvutil#csv_reader())
endfunction

function! s:base.untabularize(motion_wise, writer) "{{{3
  let [reg_0, lines] = s:read_op(a:motion_wise)
  if empty(lines)
    return
  endif
  let cw = a:writer
  let lines = self.restore_from_lines(lines)
  let s = cw.grid(lines).render()
  call s:replace_op(a:motion_wise, s, reg_0)
endfunction

function! s:base.untabularize_tsv(motion_wise) "{{{3
  return self.untabularize(a:motion_wise, csvutil#tsv_writer())
endfunction

function! s:base.untabularize_csv(motion_wise) "{{{3
  return self.untabularize(a:motion_wise, csvutil#csv_writer())
endfunction

" Interface "{{{1
function! operator#tabular#base#new() "{{{2
  return s:base.new()
endfunction

function! operator#tabular#base#debug() "{{{2
  echo join(s:logs, "\n")
endfunction

" Misc "{{{1
function! s:read_op(motion_wise) "{{{2
  let reg_0 = [@0, getregtype('0')]
  let vc = s:get_visual_command(a:motion_wise)
  execute 'normal!' '`[' . vc . '`]"0y'
  let lines = split(@0, "\n")
  return [reg_0, lines]
endfunction

function! s:replace_op(motion_wise, s, reg_0) "{{{2
  let reg_0 = a:reg_0
  let vc = s:get_visual_command(a:motion_wise)
  let @0 = a:s
  execute 'normal!' '`[' .vc. '`]"0P`['
  call setreg('0', reg_0[0], reg_0[1])
endfunction

function! s:get_visual_command(motion_wise)
  if a:motion_wise ==# 'char'
    return 'v'
  elseif a:motion_wise ==# 'line'
    return 'V'
  elseif a:motion_wise ==# 'block'
    return "\<C-v>"
  endif
  echoerr 'E1: Invalid wise name:' string(a:motion_wise)
  return 'v' " fallback
endfunction

function! s:read_buffer(fline, lline) "{{{2
  if a:fline == a:lline
    let lines = getline(1, '$')
  else
    let lines = getline(a:fline, a:lline)
  endif
  return lines
endfunction

function! s:replace_buffer(text) "{{{2
  " echo a:text
  let org = @z
  let @z = a:text
  execute 'normal!' 'gv"zP'
  let @z = org
endfunction

" Utils "{{{1
function! s:strlen(s) "{{{2
  " let len = s:strchars(a:s)
  " let displen = strdisplaywidth(a:s)
  return s:strdisplaywidth(a:s)
endfunction

if exists('*strchars')
  let s:strchars=function('strchars')
else
  function! s:strchars(s) "{{{2
    return strlen(substitute(copy(a:s), ".", "x", "g"))
  endfunction
endif

if exists('*strdisplaywidth')
  let s:strdisplaywidth=function('strdisplaywidth')
else
  function s:strdisplaywidth(str, ...) "{{{2
    let chars=split(a:str, '\v.@=')
    let col=get(a:000, 0, 0)
    let curcol=col
    for char in chars
      if char[0] is# "\t"
        let curcol+=(&ts-curcol%&ts)
      else
        let charnr=char2nr(char[0])
        let curcol+=1+((0xFF00< charnr && charnr<=0xFF60) ||
              \  (0xFFE0<=charnr && charnr<=0xFFE6) ||
              \  charn==0x3000)
      endif
    endfor
    return curcol-col
  endfunction
endif

let &cpo = s:save_cpo
" __END__ {{{1
