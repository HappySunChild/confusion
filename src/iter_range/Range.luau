local calc = require("../core_calc/types")
local iter_range = require("./types")
local memory = require("../core_memory/types")

local cast_to_state = require("../core_calc/cast_to_state")
local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local peek = require("../core_use/peek")

type Self = {
	_start: calc.UsedAs<number>,
	_finish: calc.UsedAs<number>,
	_step: calc.UsedAs<number>,
} & iter_range.Range

local CLASS = table.freeze({
	type = "state",
	kind = "Range",
	timeliness = "lazy",

	_evaluate = function(self: Self)
		depend(self, self._start)
		depend(self, self._finish)
		depend(self, self._step)

		local output = self._cached_value

		table.clear(output)

		for i = peek(self._start), peek(self._finish), peek(self._step) do
			output[i] = i
		end

		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function check_dissolvable(
	start: calc.UsedAs<number>,
	finish: calc.UsedAs<number>,
	step: calc.UsedAs<number>
): (boolean, { number }?)
	if
		cast_to_state(start) ~= nil
		or cast_to_state(finish) ~= nil
		or cast_to_state(step) ~= nil
	then
		return false
	end

	start = start :: number
	finish = finish :: number
	step = step :: number

	local output = table.create(math.ceil((finish - start) / step))

	for i = start, finish, step do
		output[i] = i
	end

	return true, output
end

local function Range(
	scope: memory.Scope,
	start: calc.UsedAs<number>,
	finish: calc.UsedAs<number>,
	step: calc.UsedAs<number>?
): iter_range.Range | { number }
	step = step or 1

	local can_dissolve, constant = check_dissolvable(start, finish, step)

	if can_dissolve then
		return constant
	end

	local new_range = setmetatable({
		scope = scope,
		created_at = os.clock(),
		using = {},
		users = {},

		_cached_value = {},

		_start = start,
		_finish = finish,
		_step = step,
	}, CLASS_METATABLE)

	table.insert(scope, destructor(new_range))

	return new_range
end

return Range
