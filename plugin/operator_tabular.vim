if v:version < 700
  echoerr "does not work this version of Vim(' . v:version . ')'"
  finish
elseif exists('g:loaded_operator_tabular')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

call operator#user#define('tabular-tsv2md'        , 'operator#tabular#markdown#tabularize_tsv')
call operator#user#define('tabular-csv2md'        , 'operator#tabular#markdown#tabularize_csv')
call operator#user#define('tabular-md2tsv'      , 'operator#tabular#markdown#untabularize_tsv')
call operator#user#define('tabular-md2csv'      , 'operator#tabular#markdown#untabularize_csv')

call operator#user#define('tabular-tsv2textile'   , 'operator#tabular#textile#tabularize_tsv')
call operator#user#define('tabular-csv2textile'   , 'operator#tabular#textile#tabularize_csv')
call operator#user#define('tabular-textile2tsv' , 'operator#tabular#textile#untabularize_tsv')
call operator#user#define('tabular-textile2csv' , 'operator#tabular#textile#untabularize_csv')

call operator#user#define('tabular-tsv2backlog'   , 'operator#tabular#backlog#tabularize_tsv')
call operator#user#define('tabular-csv2backlog'   , 'operator#tabular#backlog#tabularize_csv')
call operator#user#define('tabular-backlog2tsv' , 'operator#tabular#backlog#untabularize_tsv')
call operator#user#define('tabular-backlog2csv' , 'operator#tabular#backlog#untabularize_csv')


let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_operator_tabular = 1

" vim: foldmethod=marker
" __END__ {{{1
