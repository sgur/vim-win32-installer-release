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
command! -nargs=0 Win32InstallerGetLatest  call win32installer#download(1)
command! -nargs=0 Win32InstallerGetReleases  call win32installer#download(0)


let g:win32installer_curl_options = get(g:, 'win32installer_curl_options', [])

if get(g:, 'win32installer_autostart', 0)
  Win32InstallerGetLatest
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim:set et:
