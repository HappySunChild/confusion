local logging = require("../core_logging/types")
local memory = require("../core_memory/types")
local state = require("./types")

local cleanup = require("../core_memory/cleanup")
local derive_scope = require("../core_memory/derive_scope")
local destructor = require("../core_memory/destructor")
local generic_use = require("../core_use/generic_use")
local is_similar = require("./is_similar")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")
local parse_error = require("../core_logging/parse_error")

type Self<T, S> = {
	_inner_scope: memory.Scope<S>?,
	_processor: state.ComputedProcessor<S, T>,
	_use: state.Use,
} & state.Computed<T>

local CLASS = table.freeze({
	type = "state",
	kind = "Computed",
	timeliness = "lazy",

	_evaluate = function<T, S>(self: Self<T, S>): boolean
		if self.scope == nil then
			return false
		end

		local outer_scope = self.scope
		local inner_scope = derive_scope(outer_scope)

		local ok, new_value = xpcall(self._processor, parse_error, self._use, inner_scope)

		if ok then
			local similar = is_similar(self._cached_value, new_value)

			cleanup(self._inner_scope)

			self._inner_scope = inner_scope
			self._cached_value = new_value

			return not similar
		end

		cleanup(inner_scope)

		log_error_nonfatal(state.callback_error, new_value :: logging.Error)

		return false
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_computed<T, S>(computed: Self<T, S>)
	cleanup(computed._inner_scope)
	computed._inner_scope = nil
end

local function Computed<T, S>(scope: memory.Scope<S>, processor: state.ComputedProcessor<S, T>): state.Computed<T>
	local new_computed: Self<T, S> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		_cached_value = nil,

		_inner_scope = nil,
		_processor = processor,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_computed, destroy_computed)

	new_computed._oldest_task = oldest_task
	new_computed._use = generic_use(new_computed)

	table.insert(scope, oldest_task)

	return new_computed
end

return Computed
