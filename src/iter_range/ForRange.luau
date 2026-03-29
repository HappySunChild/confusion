local calc = require("../core_calc/types")
local iter = require("../iter/types")
local iter_range = require("./types")
local memory = require("../core_memory/types")

local Iter = require("../iter/Iter")
local RangeDisassembly = require("./RangeDisassembly")
local cast_to_state = require("../core_calc/cast_to_state")
local cleanup = require("../core_memory/cleanup")
local dissolving_use = require("../core_use/dissolving_use")
local inner_scope = require("../core_memory/inner_scope")

local function check_dissolvable<S, T>(
	scope: memory.Scope<S>,
	start: calc.UsedAs<number>,
	finish: calc.UsedAs<number>,
	step: calc.UsedAs<number>,
	processor: iter_range.RangeDisassemblyProcessor<S, T>
): (boolean, { [number]: T }?)
	if
		cast_to_state(start) ~= nil
		or cast_to_state(finish) ~= nil
		or cast_to_state(step) ~= nil
	then
		return false
	end

	local dissolving_scope = inner_scope(scope)

	local output = {}

	for index = start :: number, finish :: number, step :: number do
		local ok, value = pcall(processor, dissolving_use, dissolving_scope, index)

		if not ok then
			cleanup(dissolving_scope)

			return false, nil
		end

		output[index] = value
	end

	return true, output
end

local function ForRange<S, T>(
	scope: memory.Scope<S>,
	start: calc.UsedAs<number>,
	finish: calc.UsedAs<number>,
	processor: iter_range.RangeDisassemblyProcessor<S, T>,
	step: calc.UsedAs<number>?
): iter.Iter<number, T> | { T }
	step = step or 1

	-- local can_dissolve, constant = check_dissolvable(scope, start, finish, step, processor)

	-- if can_dissolve then
	-- 	return constant
	-- end

	return Iter(scope, RangeDisassembly(scope, processor, start, finish, step))
end

return ForRange
