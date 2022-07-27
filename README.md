# Eswpoch - Nvim

Toggles a menu which allows swapping between units and human readable strings of a configurable set of timezones
for a given timestamp. Port of the original VSCode plugin: https://github.com/hlucco/eswpoch.

## Example

![example gif](https://raw.githubusercontent.com/hlucco/nvim-eswpoch/master/example.gif)

## Installation

Using a plugin manager:

`Plug 'hlucco/nvim-eswpoch'`

## Commands

`:Eswpoch` -> Brings up the epoch swap menu.

## Overview

Once the cursor is over a valid timestamp value, using the `:Eswpoch` command the menu will open
and display the detected timestamp value in the user input bar. The options will be the supported conversations for that timestamp. Exit the menu and 
change nothing or cycle through the options and select one to cycle out. The old value will be replaced with the new value converted in line.

In addition to unit conversions, the menu will also show a converted human readable string for all of the IANA time zones that have been added to the
`timezones` variable in `lua/eswpoch.lua`. Selecting one of these strings will swap the original value for the selected human readable string. 

## Configuration

To add or remove time zone options from the menu, edit the `timezones` table in `lua/eswpoch.lua` to add
or remove timezone entries. Each timezone entry must be accompanied by it's GMT offset value. For example,
`-7` for `America/Los_Angeles`.

```lua
timezones = {
    America_Los_Angeles = -7,
    America_Chicago = -5,
    America_New_York = -4
}
```

To change the command which activates the menu, update the `plugin/eswpoch.vim` command entry
with a desired command string for activation.

```lua
command! <command> lua require'eswpoch'.eswpoch()
```

Version 1.0.0
