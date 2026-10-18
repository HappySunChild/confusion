const butler = require("@butler/butler")
const butler_chrono = require("@butler/hooks/butler_chrono")
const butler_pretty = require("@butler/hooks/butler_pretty")

const ExternalScheduler = require("@fusion/core_external/ExternalScheduler")

const SpecScheduler = require("./SpecScheduler")
const config = require("./config")

ExternalScheduler.set_scheduler(SpecScheduler)

const configured = butler({
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

const configured_units = {}

for _, unit in config.all_units do
	table.insert(configured_units, unit(configured))
end

configured.run_units(configured_units)
