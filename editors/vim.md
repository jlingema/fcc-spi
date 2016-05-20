# VIM

Make sure `<tab>` creates two spaces and no tab-character
~~~{.vim}
set tabstop=4 softtabstop=0 expandtab shiftwidth=2 smarttab
~~~

Color the 120th column to avoid too long lines:
~~~{.vim}
if exists('+colorcolumn')
  set colorcolumn=120
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>120v.\+', -1)
endif
~~~

Remove trailing spaces when saving (may replace the `*` with e.g. `*.py` to only do it for python files):
~~~{.vim}
autocmd BufWritePre * :%s/\s\+$//e
~~~
