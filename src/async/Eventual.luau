local async = require("./types")
local calc = require("../core_calc/types")
local graph = require("../core_graph/types")
local logging = require("../core_logging/types")
local memory = require("../core_memory/types")

local ExternalScheduler = require("../core_external/ExternalScheduler")
local cancel_task = ExternalScheduler.cancel_task
local do_task_immediate = ExternalScheduler.do_task_immediate

local cast_to_state = require("../core_calc/cast_to_state")
local change = require("../core_graph/change")
local cleanup = require("../core_memory/cleanup")
local depend = require("../core_graph/depend")
local derive_scope = require("../core_memory/derive_scope")
local destructor = require("../core_memory/destructor")
local evaluate = require("../core_graph/evaluate")
local is_similar = require("../core_calc/is_similar")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")
local parse_error = require("../core_logging/parse_error")
local peek = require("../core_use/peek")

type Self<T, S> = async.Eventual<T> & {
	_inner_scope: memory.Scope<S>,
	_processor: async.EventualProcessor<S, T>,

	_pending_value: T,
	_old_value: T?,

	_is_becoming: boolean,
	_active_thread: thread?,

	_session_used: { [graph.GraphNode]: true },
	_become: (any) -> (),
	_use: calc.Use,
}

local function handle_eventual_computation<T, S>(eventual: Self<T, S>)
	eventual._active_thread = coroutine.running()

	local inner_scope = derive_scope(eventual.scope)

	local ok, err: logging.Error =
		xpcall(eventual._processor, parse_error, eventual._use, inner_scope, eventual._become)

	if ok then -- adopt computation scope, clean up old one
		cleanup(eventual._inner_scope)
		eventual._inner_scope = inner_scope
	else -- throw away computation scope, invalidated because computation errored
		cleanup(inner_scope)
		log_error_nonfatal(calc.callback_error, err)
	end

	eventual._active_thread = nil
end

local CLASS = table.freeze({
	type = "State",
	kind = "Eventual",
	timeliness = "eager",

	is_pending = function<T, S>(self: Self<T, S>)
		return self._active_thread ~= nil
	end,

	_evaluate = function<T, S>(self: Self<T, S>): boolean
		if self.scope == nil then
			return false
		end

		-- calling `become` causes the Eventual to be reevaluated, but we don't want to completely reevaluate everything
		if self._is_becoming then
			self._is_becoming = false

			return not is_similar(self._old_value, self._cached_value)
		end

		-- cancel any currently active computations
		if self._active_thread ~= nil then
			cancel_task(self._active_thread)
			self._active_thread = nil
		end

		-- clear our dependencies, because we're starting a new computation that may not rely on our old dependencies
		table.clear(self._session_used)

		self._cached_value = self._pending_value
		self._old_value = self._pending_value

		-- start computation
		do_task_immediate(handle_eventual_computation, self)

		return not is_similar(self._old_value, self._cached_value)
	end,
})
local METATABLE = table.freeze({ __index = CLASS })

local function generate_callbacks<T, S>(eventual: Self<T, S>): (calc.Use, (any) -> ())
	local session_used = eventual._session_used

	local function use(target: calc.UsedAs<T>): T
		if cast_to_state(target) ~= nil then
			depend(eventual, target)

			session_used[target] = true
		end

		return peek(target)
	end

	local function become(target_value: T)
		local old_value = eventual._cached_value

		eventual._old_value = old_value
		eventual._cached_value = target_value

		if eventual.validity == "busy" then
			return
		end

		eventual._is_becoming = true

		change(eventual)

		for target in session_used do
			depend(eventual, target)
		end
	end

	return use, become
end

local function destroy_eventual<T, S>(eventual: Self<T, S>)
	if eventual._active_thread ~= nil then
		cancel_task(eventual._active_thread)
	end

	eventual._session_used = nil

	cleanup(eventual._inner_scope)
	eventual._inner_scope = nil
end

local function Eventual<T, S>(
	scope: memory.Scope<S>,
	processor: async.EventualProcessor<S, T>,
	pending_value: T
): async.Eventual<T>
	local new_eventual: Self<T, S> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		_cached_value = pending_value,
		_pending_value = pending_value,
		_old_value = nil,

		_is_becoming = false,
		_session_used = {},
		_inner_scope = nil,
		_processor = processor,
	}, METATABLE) :: any

	new_eventual._use, new_eventual._become = generate_callbacks(new_eventual)

	table.insert(scope, destructor(new_eventual, destroy_eventual))

	evaluate(new_eventual, true)

	return new_eventual
end

return Eventual
