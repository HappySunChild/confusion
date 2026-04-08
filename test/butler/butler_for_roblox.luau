local butler = require("./butler")
local butler_chrono = require("./hooks/butler_chrono")
local butler_pretty = require("./hooks/butler_pretty")

export type Options = {
	pretty: {
		disable_emoji: boolean?,
		disable_unicode: boolean?,
	}?,
}

export type Configured = butler.Configured

local function butler_for_roblox(options: Options): butler.Configured
	local new_butler = butler({
		hooks = {
			butler_chrono,
			butler_pretty({
				disable_color = true,
				disable_emoji = options.pretty and options.pretty.disable_emoji,
				disable_unicode = options.pretty and options.pretty.disable_unicode,
				hooks = { butler_chrono },
			}),
		},
	})

	return new_butler
end

return butler_for_roblox
