# macaltkey.nvim

A simple plug-in to make setting alt/option keybinds easier.

In some terminals (e.g. iTerm2, wezTerm), it is possible to set a keybind for
option-a as follows:

```lua
vim.keymap.set("n", "å", {mapping}, {opts})
```

When you have many of these, it is hard to read the configs. This plugin
allows you to write the following:

```lua
local mak = require"macaltkey"
mak.keymap.set("n", "<a-a>", {mapping}, {opts}, {opts2})
```

`{opts2}` can hold additional options that override those in `mak.setup`.
This is implemented as a dict with a simple wrapper around vim.keymap.set.
We implement the following convenience functions

```lua
mak.keymap.set
mak.keymap.del
mak.nvim_set_keymap
mak.nvim_buf_set_keymap
mak.nvim_del_keymap
mak.nvim_buf_del_keymap
mak.convert
```

These commands will transparently pass to the wrapped api function if Mac OS
is not detected, or if there are no commands like `<a-.>` detected.

If you previously wrote

```lua
local set = vim.keymap.set
```

you can now simply write

```lua
local set = mak.keymap.set
```

One can also manually convert the lhs:

```lua
local mak = require"macaltkey"
vim.keymap.set("n", mak.convert("<a-a>"), {mapping}, {opts}, {opts2})
```

If you want some help converting your older keymaps, there is a deconvert function that takes in a converted string and outputs the corresponding <a-.> command:

```lua
mak.deconvert("") == "<a-K>"
```

# Default setup

with Lazy.nvim:

```lua
require("lazy").setup({
    {
        "clvnkhr/macaltkey.nvim",
        config = function()
            require"macaltkey".setup()
        end
    }
})
```

# Setup options

with Lazy.nvim:

```lua
require("lazy").setup({
    {
        "clvnkhr/macaltkey.nvim",

        config = function()
            require"macaltkey".setup({
            language = "en-US", -- American
            -- or "en-GB" British. US is default

            modifier = 'a',
            -- If this is e.g. 'y', then
            -- will convert <y-x> to the character at option-x.
            -- Can be passed to the extra opts table of the
            -- convenience functions.

            double_set = false,
            -- If this is true, then will set both the converted
            -- and unconverted keybind, e.g. both <a-a> and å.
            -- Can be passed to the extra opts table of the
            -- convenience functions.
            })

            -- I don't recommend it, but you can put
            -- require"macaltkey".os = "darwin" here to force conversions.
            -- require"macaltkey".dict = {...} here to use a custom dict.

        end
    }
})
```

It is possible to define your own dicts but non-ascii characters may need special
code in mak.convert (see the implementation for `"en-GB"`, which has to treat £ as
two characters `'\194\163'`; contributions welcome for other layouts.)

# Acknowledgements

Inspiration from
['Neovim Lua Plugin From Scratch' by TJ DeVries and bashbunni ](https://www.youtube.com/watch?v=n4Lp4cV8YR0)
and ['Create Neovim Plugins with Lua' by DevOnDuty](https://www.youtube.com/watch?v=wkxtHV1hzEY)

The get_os function is from [f-person/auto-dark-mode.nvim](https://github.com/f-person/auto-dark-mode.nvim).
