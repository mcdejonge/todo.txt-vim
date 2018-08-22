" File:        todo.txt.vim
" Description: Todo.txt filetype detection
" Author:      Leandro Freitas <freitass@gmail.com>
" License:     Vim license
" Website:     http://github.com/freitass/todo.txt-vim
" Version:     0.4

" Export Context Dictionary for unit testing {{{1
function! s:get_SID()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

function! todo#txt#__context__()
    return { 'sid': s:SID, 'scope': s: }
endfunction

" Functions {{{1
function! s:remove_priority()
    :s/^(\w)\s\+//ge
endfunction

function! s:get_current_date()
    return strftime('%Y-%m-%d')
endfunction

function! todo#txt#prepend_date()
    execute 'normal! I' . s:get_current_date() . ' '
endfunction

function! todo#txt#replace_date()
    let current_line = getline('.')
    if (current_line =~ '^\(([a-zA-Z]) \)\?\d\{2,4\}-\d\{2\}-\d\{2\} ') &&
                \ exists('g:todo_existing_date') && g:todo_existing_date == 'n'
        return
    endif
    execute 's/^\(([a-zA-Z]) \)\?\(\d\{2,4\}-\d\{2\}-\d\{2\} \)\?/\1' . s:get_current_date() . ' /'
    let date_pos = match(current_line, s:get_current_date())
endfunction

function! todo#txt#deprioritize()
    call s:remove_priority()
endfunction

function! todo#txt#mark_as_done()
    call s:remove_priority()
    call todo#txt#prepend_date()
    execute 'normal! Ix '
endfunction

function! todo#txt#mark_all_as_done()
    :g!/^x /:call todo#txt#mark_as_done()
endfunction

function! s:append_to_file(file, lines)
    let l:lines = []

    " Place existing tasks in done.txt at the beggining of the list.
    if filereadable(a:file)
        call extend(l:lines, readfile(a:file))
    endif

    " Append new completed tasks to the list.
    call extend(l:lines, a:lines)

    " Write to file.
    call writefile(l:lines, a:file)
endfunction

function! todo#txt#remove_completed()
    " Check if we can write to done.txt before proceeding.

    let l:target_dir = expand('%:p:h')
    let l:todo_file = expand('%:p')
    let l:done_file = substitute(substitute(l:todo_file, 'todo.txt$', 'done.txt', ''), 'Todo.txt$', 'Done.txt', '')
    if !filewritable(l:done_file) && !filewritable(l:target_dir)
        echoerr "Can't write to file 'done.txt'"
        return
    endif

    let l:completed = []
    :g/^x /call add(l:completed, getline(line(".")))|d
    call s:append_to_file(l:done_file, l:completed)
endfunction

function! todo#txt#sort_by_context() range
    execute a:firstline . "," . a:lastline . "sort /\\(^\\| \\)\\zs@[^[:blank:]]\\+/ r"
endfunction

function! todo#txt#sort_by_project() range
    execute a:firstline . "," . a:lastline . "sort /\\(^\\| \\)\\zs+[^[:blank:]]\\+/ r"
endfunction

function! todo#txt#sort_by_date() range
    let l:date_regex = "\\d\\{2,4\\}-\\d\\{2\\}-\\d\\{2\\}"
    execute a:firstline . "," . a:lastline . "sort /" . l:date_regex . "/ r"
    execute a:firstline . "," . a:lastline . "g!/" . l:date_regex . "/m" . a:lastline
endfunction

function! todo#txt#sort_by_due_date() range
    let l:date_regex = "due:\\d\\{2,4\\}-\\d\\{2\\}-\\d\\{2\\}"
    execute a:firstline . "," . a:lastline . "sort /" . l:date_regex . "/ r"
    execute a:firstline . "," . a:lastline . "g!/" . l:date_regex . "/m" . a:lastline
endfunction

" Increment and Decrement The Priority
:set nf=octal,hex,alpha

function! todo#txt#prioritize_increase()
    normal! 0f)h
endfunction

function! todo#txt#prioritize_decrease()
    normal! 0f)h
endfunction

function! todo#txt#prioritize_add(priority)
    " Need to figure out how to only do this if the first visible letter in a line is not (
    :call todo#txt#prioritize_add_action(a:priority)
endfunction

function! todo#txt#prioritize_add_action(priority)
    execute 's/^\(([a-zA-Z]) \)\?/(' . a:priority . ') /'
endfunction


" Process a todo file. If we find a line with the current date:
" * If it has a token "every_\d+" give it the priority (A) and copy it
"   to a date \d+ days in the future.
" * Requires the speeddating plugin to be installed.
function! todo#txt#process()
    let today = strftime('%Y-%m-%d')

    " First we're going to update the time stamp for every line that has
    " a timestamp before today to today.
    :call map(filter(getline(1, '$'), 'v:val =~ "\\d\\d\\d\\d-\\d\\d-\\d\\d"'), 'todo#txt#process_update_timestamp(v:val, today)')

    " Loop through every line that matches the current date, check if it
    " contains an "every_" token and duplicate it, changing the date, if it
    " does.
    :call map(filter(filter(getline(1, '$'), 'v:val =~ "'. today . '"'), 'v:val =~ "\\vevery_\\d+"'), 'todo#txt#process_duplicate(v:val, today)')

    " Now that we've duplicated al lines for today and given the duplicates a 
    " new date set the priority of all lines with the current date "to 'A'.
    :call map(filter(getline(1, '$'), 'v:val =~ "'. today . '"'), 'todo#txt#process_prioritize(v:val, today)')

    :sort

    " Somewhere something sloppy is going on that adds extra spaces. Given the
    " time, just fix it the ugly way.
    :s/\s\s*/ /g

endfunction

" Update timestamps. Timestamps before today are updated to today. All
" priorities are removed from lines with timestamps.
" param line: the line to process
" param today:  the current date in YYYY-mm-dd . This saves having to calculate
"               this for every line
function! todo#txt#process_update_timestamp(line, today)
    execute '/\V' . escape(a:line,'\/')
    let l:timestamp = matchstr(a:line, '\v\d{4}-\d{2}-\d{2}')
    let l:timestamp_numeric = substitute(l:timestamp, '-', '', '')
    let l:today_numeric = substitute(a:today, '-', '', '')
    if l:timestamp_numeric < l:today_numeric
        call setline(line('.'), substitute(a:line, l:timestamp, a:today, ''))
    endif
    :s/^(\w)\s\+//ge
endfunction
" Set the priority to all lines with the current date to 'A'
" param line: the line to process
" param today:  the current date in YYYY-mm-dd . This saves having to calculate
"               this for every line
function! todo#txt#process_prioritize(line, today)
    execute '/\V' . escape(a:line,'\/')
    execute 's/^/(A) /'
endfunction

" Duplicate a line that is to be repeated.
" param line:   the line to process
" param today:  the current date in YYYY-mm-dd . This saves having to calculate
"               this for every line
function! todo#txt#process_duplicate(line, today)
    " First, find all instances of the requested line and delete them. This
    " is to avoid creating duplicates. At the end we will have ONE line for
    " today and ONE line for the next iteration
    let clean_line = substitute(a:line, a:today, '', '')
    call map(filter(getline(1, '$'), 'v:val =~ "' . clean_line . '"'), 'todo#txt#process_delete_line(v:val)')
    execute 'normal!Go' . a:today . ' ' . clean_line
    execute 'normal!yypk'
    execute 'normal!j^' 
    let increment = matchstr(a:line, '\vevery_\d+')
    let increment = substitute(increment, 'every_', '', '')
    let date_pos = match(a:line, a:today)
    execute 'normal!' . date_pos . 'l5e'
    call speeddating#increment(increment)

endfunction

" Helper function for deleting a specific line.
" param line the line to delete
function! todo#txt#process_delete_line(line)
    execute '/\V' . escape(a:line,'\/')
    execute 'normal!dd'
endfunction

" Modeline {{{1
" vim: ts=8 sw=4 sts=4 et foldenable foldmethod=marker foldcolumn=1
