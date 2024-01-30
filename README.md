<!-- LTeX: enabled=false -->
# nvim-puppeteer 🎎
<!-- LTeX: enabled=true -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-puppeteer">
<img alt="Shield" src="https://dotfyle.com/plugins/chrisgrieser/nvim-puppeteer/shield"/></a>

Master of strings. Automatically convert strings to f-strings or template
strings and back.

<!-- toc -->

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Special Case: Formatted Strings in Lua](#special-case-formatted-strings-in-lua)
- [Credits](#credits)

<!-- tocstop -->

## Features
- When typing `{}` in a **Python string** automatically converts it to an f-string.
- Adding `${}` or a line break in a **JavaScript string** automatically converts
  it to a template string. (Also works in related languages like JS-React or
  Typescript.)
- Typing `%s` in a **non-pattern Lua string** automatically converts it to a
  formatted string. (Opt-in, as this has [some
  caveats](#special-case-formatted-strings-in-lua).)
- *Removing* the `{}`, `${}`, or `%s` converts it back to a regular string.
- Also works with multi-line strings and undos.
- Zero configuration. Just install and you are ready to go.

## Requirements
- nvim 0.9 or higher.
- The respective Treesitter parsers: `:TSInstall python javascript typescript`.
  (Installing them requires
  [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).)

## Installation

```lua
-- lazy.nvim
{ 
	"chrisgrieser/nvim-puppeteer",
	lazy = false, -- plugin lazy-loads itself. Can also load on filetypes.
},

-- packer
use { "chrisgrieser/nvim-puppeteer" }
```

There is no `.setup()` call. The plugin already automatically loads as little as
possible.

You can disable `nvim-puppeteer` only for specific filetypes via:
```lua
vim.g.puppeteer_disable_filetypes = { "python", "astro" }
```

> [!NOTE]
> When using `lazy.nvim`, `vim.g.…` variables must be set in `init`, not in
> `config`.

## User Commands
The plugin is enabled by default and lazy-loaded upon opening a relevant file type.
In case you wish to turn of puppeteer for the current buffer, the following user
commands are provided:

- `PuppeteerToggle`: Toggle puppeteer for the current buffer.
- `PuppeteerDisable`: Disable puppeteer for the current buffer.
- `PuppeteerEnable`: Enable puppeteer for the current buffer.

## Special Case: Formatted Strings in Lua
Through
[string.format](https://www.lua.org/manual/5.4/manual.html#pdf-string.format),
there are also formatted strings in Lua. However, auto-conversions are far more
difficult in lua `%s` is used as a placeholder for `string.format` and [as class
in lua patterns](https://www.lua.org/manual/5.4/manual.html#6.4.1) at the same
time. While it is possible to identify in some cases whether a lua string is
used as pattern, there are certain cases where that is not possible:

```lua
-- desired: conversion to format string when typing the placeholder "%s"
local str = "foobar %s baz" -- before
local str = ("foobar %s baz"):format() -- after

-- problem case that can be dealt with: "%s" used as class in lua pattern
local found = str:find("foobar %s")

-- problem case that cannot be dealt with: "%s" in string, which
-- is only later used as pattern
local pattern = "foobar %s baz"
-- some code…
str:find(pattern)
```

Since the auto-conversion of lua strings can result in undesired false
conversions, the feature is opt-in only. This way, you can decide for yourself
whether the occasional false positive is worth it for you or not.

```lua
-- enable auto-conversion of lua strings (default: false)
vim.g.puppeteer_lua_format_string = true
```

> [!NOTE]
> After enabling, you can also set the variable to `false` temporarily to pause
> the auto-conversion. This can be useful if only one specific string gives you
> trouble.

## Credits
<!-- vale Google.FirstPerson = NO -->
**About Me**  
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

**Blog**  
I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

**Profiles**  
- [reddit](https://www.reddit.com/user/pseudometapseudo)
- [Discord](https://discordapp.com/users/462774483044794368/)
- [Academic Website](https://chris-grieser.de/)
- [Twitter](https://twitter.com/pseudo_meta)
- [Mastodon](https://pkm.social/@pseudometa)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img height='36'
style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
