let s:save_cpo = &cpo
set cpo&vim

let s:instance = operator#tabular#base#new()

function! s:instance.new() "{{{2
  return extend({}, self)
endfunction

function! s:instance.convert_item(item) "{{{2
  return " " . a:item . " "
endfunction

function! s:instance.render(lines) "{{{2
  call self.log("preprocess start")
  call self.preprocess(a:lines)
  call self.log("preprocess end")

  let bufs = self.lines()
  call self.log("start", bufs)
  let lines = []
  let head_arr = get(remove(bufs, 0, 0), 0, [])
  let s = join(self.fill_items(head_arr), "|")
  call add(lines, substitute(s, '\s\+$', '', ''))
  call add(lines, join(self.make_separator("-"), "|"))
  for line in bufs
    let s = join(self.fill_items(map(line, 'substitute(v:val, "[\\r\\n]", "<br>", "")')), "|")
    call add(lines, substitute(s, '\s\+$', '', ''))
  endfor
  call self.log("finish", lines)
  " echo lines
  return join(lines, "\n")
endfunction

function! s:instance.restore_from_lines(buflines) "{{{2
  let buflines = copy(a:buflines)
  " remove sep
  call remove(buflines, 1, 1)

  let lines = map(buflines, 'self.mdcolumn2tsv(self.split_and_trim(v:val, "|"))')
  return lines
endfunction

function! s:instance.mdcolumn2tsv(line) "{{{2
  call map(a:line, 'substitute(v:val, "^ \\| $", "", "")')
  return map(a:line, 'substitute(v:val, "<br\\s*/\\?>", "\\n", "i")')
endfunction


" Interface {{{1
function! operator#tabular#markdown#new() "{{{2
  return s:instance.new()
endfunction

function! operator#tabular#markdown#tabularize_tsv(motion_wiseness)
  return s:instance.new().tabularize_tsv(a:motion_wiseness)
endfunction

function! operator#tabular#markdown#untabularize_tsv(motion_wiseness)
  return s:instance.new().untabularize_tsv(a:motion_wiseness)
endfunction

function! operator#tabular#markdown#tabularize_csv(motion_wiseness)
  return s:instance.new().tabularize_csv(a:motion_wiseness)
endfunction

function! operator#tabular#markdown#untabularize_csv(motion_wiseness)
  return s:instance.new().untabularize_csv(a:motion_wiseness)
endfunction

let &cpo = s:save_cpo
" __END__ {{{1
