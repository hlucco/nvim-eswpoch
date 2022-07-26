" Last Change: 2022 July 22
" Maintainer: hlucco@gmail.com
" License: MIT License

"This line prevents loading the file twice
if exists('g:loaded_eswpoch') | finish | endif

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

command! Eswpoch lua require'eswpoch'.eswpoch()

let &cpo = s:save_cpo " restore after
unlet s:save_cpo

let g:loaded_eswpoch = 1
