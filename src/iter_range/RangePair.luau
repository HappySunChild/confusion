local calc = require("../core_calc/types")
local iter_range = require("./types")
local logging = require("../core_logging/types")
local memory = require("../core_memory/types")

local cleanup = require("../core_memory/cleanup")
local derive_scope = require("../core_memory/derive_scope")
local destructor = require("../core_memory/destructor")
local generic_use = require("../core_use/generic_use")
local is_similar = require("../core_calc/is_similar")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")
local mark_dirty = require("../core_graph/mark_dirty")
local parse_error = require("../core_logging/parse_error")

type Self<T, S> = {
	_inner_scope: memory.Scope<S>,
	_processor: iter_range.RangeDisassemblyProcessor<T, S>,
	_use: calc.Use,

	_input_index: number,
} & iter_range.RangePair<T>

local CLASS = table.freeze({
	type = "state",
	kind = "RangePair",
	timeliness = "lazy",

	invalidate_index = function<T, S>(self: Self<T, S>, new_index: number)
		if is_similar(self._input_index, new_index) then
			return
		end

		self._input_index = new_index

		mark_dirty(self)
	end,

	_evaluate = function<T, S>(self: Self<T, S>)
		if self.scope == nil then
			return false
		end

		local inner_scope = derive_scope(self.scope)
		local ok, output_value =
			xpcall(self._processor, parse_error, self._use, inner_scope, self._input_index)

		if not ok then
			cleanup(inner_scope)

			log_error_nonfatal(calc.callback_error, output_value :: logging.Error)

			return false
		end

		cleanup(self._inner_scope)
		self._inner_scope = inner_scope

		local old_value = self._cached_value

		self._cached_value = output_value

		return not is_similar(old_value, output_value)
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_rangepair<T, S>(rangepair: Self<T, S>)
	cleanup(rangepair._inner_scope)
	rangepair._inner_scope = nil
end

local function RangePair<S, T>(
	scope: memory.Scope<S>,
	initial_index: number,
	processor: iter_range.RangeDisassemblyProcessor<S, T>
): iter_range.RangePair<T>
	local new_rangepair: Self<T, S> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		_cached_value = nil,

		_input_index = initial_index,

		_inner_scope = nil,
		_processor = processor,
	}, CLASS_METATABLE) :: any

	new_rangepair._use = generic_use(new_rangepair)

	table.insert(scope, destructor(new_rangepair, destroy_rangepair))

	return new_rangepair
end

return RangePair
