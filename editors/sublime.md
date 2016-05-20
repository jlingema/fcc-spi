# Textmate-Style editors
Should be supported by:
- Textmate
- Sublime-text 2/3 (tested)
- Visual Studio Code

## Global settings
May be put in global settings file:
~~~~{.json}
{
    "ensure_newline_at_eof_on_save": true,
    "trim_trailing_white_space_on_save": true,
    "rulers": [120]
}
~~~~

## Syntax specific settings
Put this in the syntax specific files for C++ and Python (may want to put 4 as default as that is PEP8 standard):
~~~~{.json}
{
    "tab_size": 2,
    "translate_tabs_to_spaces": true
}
~~~~
