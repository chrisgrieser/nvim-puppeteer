<!-- LTeX: enabled=false -->
# nvim-puppeteer <!-- LTeX: enabled=true --> 🎎
<!-- <a href="https://dotfyle.com/plugins/chrisgrieser/nvim-puppeteer"><img src="https://dotfyle.com/plugins/chrisgrieser/nvim-puppeteer/shield" /></a> -->

Master of strings. Automatically convert strings to f-strings or template strings and back.

## Features
- When typing `{}` in a python string, automatically convert it to a f-string. 
- When typing `${}` in a javascript or typescript string, automatically convert it to a template string.
- When *removing* the `{}` or `${}`, automatically convert it back to a regular string.
- Also works with multi-line strings.
- No configuration needed, just install and you are ready to go.

## Installation

```lua
-- lazy.nvim
{ 
	"chrisgrieser/nvim-puppeteer",
	dependencies = "nvim-treesitter/nvim-treesitter",
	ft = { "python", "javascript", "typescript" },
},

-- packer
use {
	"chrisgrieser/nvim-puppeteer",
	requires = "nvim-treesitter/nvim-treesitter",
}
```

The respective Treesitter parsers are required: `:TSInstall python javascript typescript`.

No configuration or `.setup()` call is needed. The plugin already automatically loads as little as possible.

## Credits
<!-- vale Google.FirstPerson = NO -->
__About Me__  
In my day job, I am a sociologist studying the social mechanisms underlying the digital economy. For my PhD project, I investigate the governance of the app economy and how software ecosystems manage the tension between innovation and compatibility. If you are interested in this subject, feel free to get in touch.

__Blog__  
I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

__Profiles__  
- [reddit](https://www.reddit.com/user/pseudometapseudo)
- [Discord](https://discordapp.com/users/462774483044794368/)
- [Academic Website](https://chris-grieser.de/)
- [Twitter](https://twitter.com/pseudo_meta)
- [Mastodon](https://pkm.social/@pseudometa)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

__Buy Me a Coffee__  
<br>
<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
