scriptencoding utf-8



" Interface {{{1

function! win32installer#download(is_only_latest) abort
  let cache = s:get_cache(a:is_only_latest)
  if !empty(cache)
    let json = json_decode(join(readfile(cache), "\n"))
    call s:process_json(json, a:is_only_latest)
    return
  endif
  let url = a:is_only_latest
        \ ? 'https://api.github.com/repos/vim/vim-win32-installer/releases/latest'
        \ : 'https://api.github.com/repos/vim/vim-win32-installer/releases'
  call job_start(['curl'] + g:win32installer_curl_options + ['--silent', url], {
        \ 'close_cb': function('s:callback', [a:is_only_latest])
        \ })
endfunction


" Internal {{{1

function! s:download(json) abort "{{{
  let asset = s:extract_asset(a:json)
  if empty(asset)
    echoerr 'No download found for' s:arch
    return
  endif

  if !isdirectory(s:directory)
    silent call mkdir(s:directory, 'p')
  endif
  call s:start_download(asset.url, s:directory . '\' . asset.name)
endfunction "}}}

function! s:confirm_with_window(name, patches, candidate) abort "{{{
  botright new +set\ buftype=nofile
  silent execute 'file' a:name
  let bufnr = bufnr('%')
  silent! bufnr.'bwipeout'
  try
    call setline(1, 'Installed: ' . s:version_string())
    call append(line('$'), printf('Download : %s', a:name))
    call append(line('$'), 'Changes:')
    for patch in a:patches
      call append(line('$'), patch)
    endfor
    redraw
    return confirm("Are you sure you want to download?", join(map(copy(a:candidate), '"&" . v:val'), "\n"), 2)
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

function! s:id_for_type(is_only_latest) abort "{{{
  return a:is_only_latest ? 'latest_' : 'releases_'
endfunction "}}}

function! s:cache_path(is_only_latest) abort "{{{
  if !empty(g:win32installer_cache_dir)
    let dir = fnamemodify(g:win32installer_cache_dir, ':p:h')
    if isdirectory(dir) && filewritable(dir) == 2
      return expand(dir. '/' . s:id_for_type(a:is_only_latest) . localtime() . '.json')
    endif
  endif
  return ''
endfunction "}}}

function! s:get_cache(is_only_latest) abort "{{{
  if empty(g:win32installer_cache_dir)
    return ''
  endif
  let dir = fnamemodify(g:win32installer_cache_dir, ':p:h')
  if !isdirectory(dir)
    return ''
  endif

  let limit = localtime() - (60 * 60)
  let ptn = s:id_for_type(a:is_only_latest) . '*.json'
  let files = sort(filter(map(globpath(dir, ptn, 1, 1), {
        \ k, v -> {
        \   'path': v,
        \   'localtime': getftime(v)
        \ }}), {k, v -> v.localtime > limit}),
        \ {v1, v2 -> v1.localtime == v2.localtime ? 0 : v1.localtime < v2.localtime ? 1 : -1})
  if empty(files)
    return ''
  endif
  return files[0].path
endfunction "}}}

function! s:callback(is_only_latest, channel) abort "{{{
  let lines = []
  while ch_canread(a:channel)
    let lines += [ch_read(a:channel)]
  endwhile
  let json = json_decode(join(lines, "\n"))
  if type(json) == v:t_dict && has_key(json, 'message')
    echoerr 'Download failed:' get(json, 'message', 'NO MESSAGE')
    return
  endif

  let path = s:cache_path(a:is_only_latest)
  if !empty(path)
    call writefile(lines, path)
  endif

  call s:process_json(json, a:is_only_latest)
endfunction "}}}

function! s:process_json(json, is_single_release) abort "{{{
  for entry in type(a:json) == v:t_dict ? [a:json] : a:json
    let name = entry.name
    let patches = split(split(entry.body, "\n\n")[2], "\n")
    let candidate = a:is_single_release ? s:confirm_single : s:confirm_plural

    let result = s:confirm_with_window(name, patches, candidate)
    if result == s:DOWNLOAD
      call s:download(entry)
      return
    elseif result == s:CANCEL
      return
    endif
  endfor
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
        \ 'exit_cb': function('s:callback_on_download', [a:path]),
        \ })
  execute 'wincmd' 'p'
endfunction "}}}

function! s:callback_on_download(vim_archive, job, status) abort "{{{
  let path = fnamemodify($VIM , ':p:h:h')
  if g:win32installer_self_update && isdirectory(path)
    let modified = !empty(filter(map(range(1, bufnr('$')), 'getbufvar(v:val, "&modified")'), 'v:val == 1'))
    let servers = filter(split(serverlist(), "\n"), "v:val !=# v:servername")
    if (empty(servers) && !modified) || confirm("Save all modified buffers and update?", "&Yes\n&No") == 1
      wall
      for server in servers
        call remote_send(server, "\<C-\\>\<C-n>:<C-u>qall!\<CR>")
      endfor
      call s:self_update(path, a:vim_archive)
    endif
  endif
  execute printf('!cmd /c start /b "" "%s"', fnamemodify(a:vim_archive, ':h'))
endfunction "}}}

function! s:self_update(path, vim_archive) abort "{{{
  if executable('unzip')
    let cmd = printf('unzip -o -d "%s" "%s"', a:path, a:vim_archive)
  elseif executable('7z')
    let cmd = printf('7z x -aoa -o"%s" "%s"', a:path, a:vim_archive)
  else
    echohl WarningMsg | echomsg "No achivers found." | echohl NONE
    return
  endif
  execute printf('!start cmd /c "%s && start /D "%s" %s"', cmd, getcwd(), v:progpath)
  qall!
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

let s:directory = fnamemodify(tempname(), ':p:r:h')
let s:arch = has('win64') ? 'x64' : 'x86'
let s:DOWNLOAD = 1
let s:SKIP = 2
let s:CANCEL = 3
silent! lockvar s:DOWNLOAD s:SKIP s:CANCEL

let s:confirm_single = ['Yes', 'No']
let s:confirm_plural = ['Yes', 'Prev', 'CANCEL']


" 1}}}
