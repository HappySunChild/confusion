<img src="./.github/assets/logo-full-dark-theme.svg#gh-dark-mode-only" alt="confusion">
<img src="./.github/assets/logo-full-light-theme.svg#gh-light-mode-only" alt="confusion">

`confusion` is an experimental, platform-agnostic fork of dphfox's [Fusion](https://github.com/dphfox/Fusion). Rather than focusing on a single runtime, such as Roblox in Fusion's case, it acts as a collection of reusable reactive primitives and utilities that can be integrated into environments like [Lute](https://lute.luau.org/), [Lune](https://github.com/lune-org/lune), or other custom runtimes.

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

This doesn't mean that 'batteries-included' packages won't be provided though, instead you will have to specifically choose what submodules you want to use.
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

TODO

## Why this fork?
Recently to me it feels like development of Fusion has slowed over time, so rather than waiting for some of the ideas I wanted to explore, I decided to experiment with them in a fork.

`confusion` focuses on a few different goals:
- Making the core library runtime-agnostic
- Experimenting with new reactive primitives and APIs
- Improving parts of the dependency graph implementation where possible
- Keeping platform-specific functionality in separate submodules

The project also serves as a place to prototype ideas that may not be appropriate for Fusion itself. Some of those ideas may eventually prove worthwhile, while others simply exist as experiments.

## Alternatives
If you're looking for some other lightweight and platform-agnostic reactive programming modules for Luau you can check out some of these projects:
- [Vide](https://github.com/centau/vide) by centau
- [Val](https://github.com/TumbleWede/Val) by TumbleWede
- [signals](https://github.com/roblox/signals) by Roblox