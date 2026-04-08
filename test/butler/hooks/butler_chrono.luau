local butler = require("../butler")
local butler_hooks = require("../butler_hooks")
local butler_pretty = require("./butler_pretty")

type UnitsRunResults = { duration: number } & butler.UnitsRunResult
type TestRunResults = { duration: number } & butler.TestRunResult

local SUFFIX_MICRO_UNICODE = "µ"
local SUFFIX_MICRO = "u"
local SUFFIX_MILLI = "m"

local MILLISECOND = 1e-3
local MICROSECOND = 1e-6

local function fmt_duration(seconds: number, options: butler_pretty.Options): string
	if seconds < 100 * MICROSECOND then -- microseconds
		return `{math.ceil(seconds / MICROSECOND * 100) / 100}{if options.disable_unicode
			then SUFFIX_MICRO
			else SUFFIX_MICRO_UNICODE}s`
	elseif seconds < 100 * MILLISECOND then -- milliseconds
		return `{math.ceil(seconds / MILLISECOND * 100) / 100}{SUFFIX_MILLI}s`
	end

	return `{math.ceil(seconds * 100) / 100}s`
end

local START_TIMES = {}

local butler_chrono: butler_hooks.Hook<butler_pretty.HookMethod> = {
	before_units = function(units)
		START_TIMES[units] = os.clock()
	end,
	after_units = function(units, units_results: UnitsRunResults)
		units_results.duration = os.clock() - START_TIMES[units]
		START_TIMES[units] = nil
	end,
	before_test = function(label: string)
		START_TIMES[label] = os.clock()
	end,
	after_test = function(label: string, test_results: TestRunResults)
		test_results.duration = os.clock() - START_TIMES[label]
		START_TIMES[label] = nil
	end,
	add_annotations = function(
		test_results: TestRunResults,
		options: butler_pretty.Options,
		add_annotation: (string) -> ()
	)
		add_annotation(fmt_duration(test_results.duration, options))
	end,
	add_line_items = function(
		units_results: UnitsRunResults,
		options: butler_pretty.Options,
		add_line_item: (string, string) -> ()
	)
		add_line_item("Total Duration", fmt_duration(units_results.duration, options))
	end,
}

return butler_chrono
