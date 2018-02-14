" win32installer
" Version: 0.0.1
" Author: sgur
" License: MIT License

if exists('g:loaded_win32installer')
  finish
endif

if !has('terminal')
  echoerr '+terminal not supported'
  finish
endif

if !executable('curl')
  echoerr 'curl is required'
  finish
endif

let g:loaded_win32installer = 1

let s:save_cpo = &cpoptions
set cpoptions&vim


command! -bang -nargs=0 Win32InstallerDownload  call win32installer#download(<bang>1)


let g:win32installer_curl_options = get(g:, 'win32installer_curl_options', [])

let g:win32installer_self_update = get(g:, 'win32installer_self_update', 0)

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim:set et:
