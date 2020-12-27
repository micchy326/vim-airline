" MIT License. Copyright (c) 2013-2020 François-Xavier Carton et al.
" Plugin: https://github.com/prabirshrestha/vim-lsp
" vim: et ts=2 sts=2 sw=2

scriptencoding utf-8

if !get(g:, 'lsp_loaded', 0)
  finish
endif

function! s:airline_lsp_count(cnt, symbol) abort
  return a:cnt ? a:symbol. a:cnt : ''
endfunction

function! s:airline_lsp_get_line_number(cnt, type) abort
  let result = ''

  if a:type ==# 'error'
    let result = lsp#get_buffer_first_error_line()
  endif

  if empty(result)
      return ''
  endif

  let open_lnum_symbol  =
    \ get(g:, 'airline#extensions#lsp#open_lnum_symbol', '(L')
  let close_lnum_symbol =
    \ get(g:, 'airline#extensions#lsp#close_lnum_symbol', ')')

  return open_lnum_symbol . result . close_lnum_symbol
endfunction

function! airline#extensions#lsp#get(type) abort
  if !exists(':LspDeclaration')
    return ''
  endif

  let error_symbol = get(g:, 'airline#extensions#lsp#error_symbol', 'E:')
  let warning_symbol = get(g:, 'airline#extensions#lsp#warning_symbol', 'W:')
  let show_line_numbers = get(g:, 'airline#extensions#lsp#show_line_numbers', 1)

  let is_err = a:type ==# 'error'

  let symbol = is_err ? error_symbol : warning_symbol

  let num = lsp#get_buffer_diagnostics_counts()[a:type]

  if show_line_numbers == 1
    return s:airline_lsp_count(num, symbol) . <sid>airline_lsp_get_line_number(num, a:type)
  else
    return s:airline_lsp_count(num, symbol)
  endif
endfunction

function! airline#extensions#lsp#get_warning() abort
  return airline#extensions#lsp#get('warning')
endfunction

function! airline#extensions#lsp#get_error() abort
  return airline#extensions#lsp#get('error')
endfunction

let g:airline#extensions#lsp#timer = 0
function! airline#extensions#lsp#progress() abort
  if get(w:, 'airline_active', 0)
    if exists('*lsp#get_progress')
      let l:lsp_progress = lsp#get_progress()
      if l:lsp_progress['messages'] != '' && l:lsp_progress['percentage'] != 100
        let percent = ''
        if type(l:lsp_progress['percentage']) == v:t_number
              \ || type(l:lsp_progress['percentage']) == v:t_float
          let percent = ' ' . string(abs(round(l:lsp_progress['percentage']*10))/10) . '%'
        endif
        if g:airline#extensions#lsp#timer == 0
          let s:title = l:lsp_progress['title']
          let g:airline#extensions#lsp#timer = timer_start(
                \ 300,
                \ 'airline#extensions#lsp#update', {'repeat' : -1})
        endif
        let messages = airline#util#shorten(l:lsp_progress['messages'] . percent, 91, 9)
        return l:lsp_progress['server'] . ':' . s:title . ' ' . messages
      endif
      call timer_stop(g:airline#extensions#lsp#timer)
      let g:airline#extensions#lsp#timer = 0
      return ''
    endif
  endif
endfunction

function! airline#extensions#lsp#init(ext) abort
  call airline#parts#define_function('lsp_error_count', 'airline#extensions#lsp#get_error')
  call airline#parts#define_function('lsp_warning_count', 'airline#extensions#lsp#get_warning')
  call airline#parts#define_function('lsp_progress', 'airline#extensions#lsp#progress')
endfunction

function! airline#extensions#lsp#update(timer)
  call airline#update_statusline()
endfunction

