vim-win32-installer-release
====

Download latest vim-win32-installer release via Vim script

Demo
----

![](.github/assets/demo.gif "Demo")

Requirement
-----------

* vim 8.0 or later with `+terminal` (including `+multi_byte`, `+job` and `+channel`)
* curl

Usage
-----

### Commands

#### Win32InstallerDownload

Download gVim Windows build (x86 or amd64) from https://github.com/vim/vim-win32-installer/releases

Without `<bang>`, Download the latest relase.
With `<bang>`, Fetch several releases and confirm wich to download.

```vim
:Win32InstallerDownload!
```

### Options

#### `g:win32installer_autostart`

Set this to 1 start downloader after loading the plugin (default: `0`)

```vim
let g:win32installer_autostart = 1
```

It is useful when the plugin is located in the `opt` folder with `packages` feature and use it via `packadd vim-win32-installer`.

#### `g:win32installer_curl_options`

Pass the option to the `curl` command as parameters (default: `[]`)

```vim
let g:win32installer_curl_options = ['--insecure']
```

Install
-------

- Install this plugin with your favorite plugin manager
- Use "Vim packages"
  1. Locate this plugin to `~/.vim/pack/downloader/start/vim-win32-installer`
  2. Or locate to `~/.vim/pack/downloader/opt/vim-win32-installer` and `:packadd vim-win32-installer`

License
-------

[MIT License](./LICENSE)

Author
------

sgur
