<!-- I SPENT SO LONG LEARNING INKSCAPE TO MAKE THESE ICONS OK -->
<img src="./.github/assets/logo-full-dark-theme.svg#gh-dark-mode-only" alt="confusion">
<img src="./.github/assets/logo-full-light-theme.svg#gh-light-mode-only" alt="confusion">

`confusion` is an experimental, platform-agnostic fork of dphfox's [Fusion](https://github.com/dphfox/Fusion).

## Compatibility with Fusion
If you're looking to switch to `confusion` from Fusion, and are wondering how much work is required to switch, you can find a full list of API changes at [`FUSION_COMPATIBILITY.md`](FUSION_COMPATIBILITY.md).

## Example Usage
This example demonstrates the reactive primitives provided by `confusion`.
```luau
-- confusion/init.luau
return {
	Value = require("@fusion/core_state/Value"),
	Computed = require("@fusion/core_state/Computed"),
	
	peek = require("@fusion/core_use/peek"),
	
	scoped = require("@fusion/core_memory/scoped"),
}
```
```luau
-- example.luau
const confusion = require("./confusion")
const peek = confusion.peek

const scope = confusion:scoped()

const first_name = scope:Value("Jane")
const last_name = scope:Value("Doe")

const full_name = scope:Computed(function(use)
	return use(first_name) .. " " .. use(last_name)
end)

print(peek(full_name)) --> Jane Doe

first_name:set("John")

print(peek(full_name)) --> John Doe
```

## Platform Support
`confusion` is designed to be as platform-agnostic as possible. It avoids depending on runtime-specific features (such as Roblox's `Instance`, tweens and task scheduler), allowing its reactive primitives to be used in a wider range of environments.

This doesn't mean that 'batteries-included' packages won't be provided though, instead you will have to specifically choose what submodules you want to use if you're not using a preexisting package.
If you find that `confusion` doesn't provide a batteries-included package for your specific runtime feel free to open an issue for it!


### Platform-specific Integration
To integrate with a specific runtime, you'll need to provide implementations for a few runtime interfaces:
* a task scheduler
* an external logger
* an external debugger

A task scheduler interface is required if you intend on using animations (modules such as `confusion/motion`, `confusion/motion_springs`, `confusion/motion_tweens` or `confusion/chrono` are dependant on an external task scheduler) or anything within the `confusion/async` module.

Here's a relatively simple example of what an external task scheduler interface for Lute could look like:
```luau
-- confusion/lute_external/LuteScheduler.luau
const task = require("@lute/task")

const external = require("@fusion/core_external/types")
const ExternalScheduler = require("@fusion/core_external/ExternalScheduler")

local scheduler_active = true

return {
	schedule_task_immediate = task.spawn,
	schedule_task_deferred = task.defer,
	schedule_task_delayed = task.delay,
	cancel_task = coroutine.close,

	start_scheduler = function()
		scheduler_active = true

		task.spawn(function()
			while scheduler_active do
				ExternalScheduler.perform_update_step()
				task.wait()
			end
		end)
	end,
	stop_scheduler = function()
		scheduler_active = false
	end,
} :: external.ExternalScheduler
```
You can then tell `confusion` to use your task scheduler interface like so:
```luau
-- confusion/confusion_for_lute.luau
const LuteScheduler = require("@fusion/lute_external/LuteScheduler")

const ExternalScheduler = require("@fusion/core_external/ExternalScheduler")
ExternalScheduler.set_scheduler(LuteScheduler)

-- ...
```

### Roblox
For Roblox users `confusion` provides a suite of utilities for building reactive `Instance` trees and user interfaces under the `confusion_for_roblox` package.

TODO installation and releases maybe

#### Rojo
For Rojo users you can simply copy and paste the `src` directory into your project wherever necessary.
It is recommended that you rename the `confusion_for_roblox.luau` file to `init.luau` so that you don't have to write `require(".../confusion/confusion_for_roblox")` every time.
You will also have to manually replace all of the `"./"` requires with the `@self/` alias so that the imports resolve correctly too.

## Why this fork?
This fork was initially a way for me to learn how Fusion works *(as a Roact asylum seeker, Fusion caught my attention for how much less work is needed to get simple things done like WOW)*
so that I could use it more effectively in some projects.

Another reason why I decided to create a fork is that recently to me it felt like development of Fusion had significantly slowed over time. So rather than waiting for some
of the features I wanted to try out to get implemented into base Fusion, I decided to try implementing them myself here.

My goals for `confusion` can essentialy be boiled down to this (in order of how important they are):
1. experimenting with new reactive primitives and utilities (like `Eventual` and `flatten`)
2. migrate towards fully runtime agnostic reactive code (mostly for running tests more easily outside of Roblox)
3. improving parts of the reactive graph implementation where possible
4. new utilities for building UIs in Roblox (such as the Stylesheets API and `Describe`)

`confusion` also serves as a place to prototype ideas that may not be appropriate for Fusion itself.
Some of those ideas may eventually prove worthwhile, while others simply exist as experiments (such as the replacement of `Observers` with `observe` and `observe_immediate`).

## Alternatives
If you're looking for some other lightweight and *somewhat* platform-agnostic reactive programming modules for Luau you can check out some of these projects:
- [Fusion](https://github.com/dphfox/Fusion) by dphfox (the base version is well enough on it's own :))
- [Vide](https://github.com/centau/vide) by centau
- [Val](https://github.com/TumbleWede/Val) by TumbleWede
- [signals](https://github.com/roblox/signals) by Roblox
- [fluid](https://github.com/ffrostfall/fluid) by ffrostfall