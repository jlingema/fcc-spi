# XCode

Trailing whitespace is removed by default in XCode. To make sure go to `Xcode > Preferences > Text Editing > Editing`,
make sure that `Automatically trim trailing whitespace` and `Including whitespace-only lines` are checked.

To display a ruler at column 120 to avoid too long lines, go to `Xcode > Preferences > Text Editing > Editing`,
check the `Page guide at column` check-box and set it to 120.

To make sure you're indenting according to the style guide go to `Xcode > Preferences > Text Editing > Indentation`,
set `Prefer indent using` to `Spaces`, set `Tab width` and `Indent width` to 2 spaces, make sure that for `Tab key` the
option `Indents always` is set (note that this may lead to problems if you edit a python 3 file that was previously
indented with tabs, since you'll be mixing tabs and spaces, we advise to convert to spaces in that case).
