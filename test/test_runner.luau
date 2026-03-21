local butler = require("@butler/butler")
local butler_chrono = require("@butler/hooks/butler_chrono")
local butler_pretty = require("@butler/hooks/butler_pretty")

local ExternalScheduler = require("@fusion/core_external/ExternalScheduler")

local SpecScheduler = require("./SpecScheduler")
local test_config = require("./test_config")

ExternalScheduler.set_scheduler(SpecScheduler)

local configured = butler({
	hooks = {
		butler_chrono,
		butler_pretty({
			disable_color = game ~= nil, -- in theory this'd work, but we don't have access to require aliases on Roblox
			disable_emoji = true,
			line_width = 100,
			hooks = { butler_chrono },
		}),
	},
})

-- running stuff

local configured_units = {}

for _, unit in test_config.all_units do
	table.insert(configured_units, unit(configured))
end

configured.run_units(configured_units)
