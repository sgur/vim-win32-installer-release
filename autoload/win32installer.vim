scriptencoding utf-8



" Interface {{{1

function! win32installer#get_latest() abort
  call job_start(['curl'] + g:win32installer_curl_options + ['--silent', 'https://api.github.com/repos/vim/vim-win32-installer/releases/latest'], {
        \ 'close_cb': function('s:callback')
        \ })
endfunction


" Internal {{{1

function! s:download(json) abort "{{{
  let asset = s:extract_asset(a:json)
  if empty(asset)
    echoerr 'No download found for' s:arch
    return
  endif

  let name = a:json.name
  let patches = split(split(a:json.body, "\n\n")[2], "\n")
  if s:confirm_with_window(name, patches)
    let path = s:directory . asset.name
    call s:start_download(asset.url, path)
  endif
endfunction "}}}

function! s:confirm_with_window(name, patches) abort "{{{
  botright new +set\ buftype=nofile
  silent execute 'file' a:name
  let bufnr = bufnr('%')
  silent! bufnr.'bwipeout'
  try
    call setline(1, 'Installed: ' . s:version_string())
    call append(line('$'), printf('Latest   : %s', a:name))
    call append(line('$'), 'Changes:')
    for patch in a:patches
      call append(line('$'), patch)
    endfor
    redraw
    return confirm("Are you ready to download?", "&Yes\n&No", 2) == 1
  finally
    execute bufnr.'bwipeout'
  endtry
  return 0
endfunction "}}}

function! s:version_string() abort "{{{
  let major = v:version / 100
  let minor = v:version % 100
  let ver_str = matchstr(split(execute('version'), "\n")[2], ':\s\zs[- ,0-9]\+$')
  let patch = max(s:parse_included_patches(ver_str))
  return printf('v%d.%d.%d', major, minor, patch)
endfunction "}}}

function! s:callback(channel) abort "{{{
  let lines = []
  while ch_canread(a:channel)
    let lines += [ch_read(a:channel)]
  endwhile
  let json = json_decode(join(lines, "\n"))
  if !has_key(json, 'assets')
    echoerr 'Download failed:' get(json, 'message', 'NO MESSAGE')
    return
  endif
  call s:download(json)
endfunction "}}}

function! s:extract_asset(json) abort "{{{
  let assets = filter(copy(a:json.assets), {k,v -> stridx(v.name, '_' . s:arch) >= 0 && stridx(v.name, '_pdb') == -1 && stridx(v.name, '.zip') >= 0 })
  call map(assets, {k,v -> {'name': v.name, 'url': v.browser_download_url}})
  return get(assets, 0, {})
endfunction "}}}

function! s:start_download(url, path) abort "{{{
  botright call term_start(['curl'] + g:win32installer_curl_options + ['--progress-bar', '--location', '--output', a:path, a:url], {
        \ 'term_name': a:url,
        \ 'term_rows': 3,
        \ 'term_finish': 'close',
        \ 'exit_cb': {job,status -> execute(printf('!cmd /c start /b "" "%s"', fnamemodify(a:path, ':h')))}
        \ })
  execute 'wincmd' 'p'
endfunction "}}}

function! s:parse_included_patches(str) abort "{{{
  let trimmed = substitute(a:str, ' ', '', 'g')
  let chunks = split(trimmed, ',')
  let patches = []
  for chunk in chunks
    let ver = split(chunk, '-')
    if len(ver) == 2
      let patches += range(ver[0], ver[1])
    else
      let patches += [ver[0]]
    endif
  endfor
  return patches
endfunction "}}}


" Initialization {{{1

let s:directory = fnamemodify(isdirectory(expand('~\Downloads')) ? '~\Downloads' : '', ':p')
let s:arch = has('win64') ? 'x64' : 'x86'


" 1}}}
