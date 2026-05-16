const async = require("./types")
const graph = require("../core_graph/types")
const logging = require("../core_logging/types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const ExternalScheduler = require("../core_external/ExternalScheduler")
const cancel_task = ExternalScheduler.cancel_task
const schedule_task_immediate = ExternalScheduler.schedule_task_immediate

const cast_to_state = require("../core_state/cast_to_state")
const change = require("../core_graph/change")
const cleanup = require("../core_memory/cleanup")
const depend = require("../core_graph/depend")
const derive_scope = require("../core_memory/derive_scope")
const destructor = require("../core_memory/destructor")
const evaluate = require("../core_graph/evaluate")
const is_similar = require("../core_state/is_similar")
const log_error_nonfatal = require("../core_logging/log_error_nonfatal")
const parse_error = require("../core_logging/parse_error")
const peek = require("../core_use/peek")

type Self<T, S> = async.Eventual<T> & {
	_inner_scope: memory.Scope<S>,
	_processor: async.EventualProcessor<S, T>,

	_pending_value: T,
	_old_value: T?,

	_is_becoming: boolean,
	_active_thread: thread?,

	_session_used: { [graph.GraphNode]: true },
	_become: (any) -> (),
	_use: state.Use,
}

const function handle_eventual_computation<T, S>(eventual: Self<T, S>)
	eventual._active_thread = coroutine.running()

	const inner_scope = derive_scope(eventual.scope)

	const ok, err: logging.Error =
		xpcall(eventual._processor, parse_error, eventual._use, inner_scope, eventual._become)

	if ok then -- adopt computation scope, clean up old one
		cleanup(eventual._inner_scope)
		eventual._inner_scope = inner_scope
	else -- throw away computation scope, invalidated because computation errored
		cleanup(inner_scope)
		log_error_nonfatal(state.callback_error, err)
	end

	eventual._active_thread = nil
end

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Eventual",
		timeliness = "eager",

		is_pending = function<T, S>(self: Self<T, S>)
			return self._active_thread ~= nil
		end,
		evaluate = function<T, S>(self: Self<T, S>): boolean
			if self.scope == nil then
				return false
			end

			-- calling `become` causes the Eventual to be reevaluated, but we don't want to completely reevaluate everything
			if self._is_becoming then
				self._is_becoming = false

				return not is_similar(self._old_value, self.cached_value)
			end

			-- cancel any currently active computations
			if self._active_thread ~= nil then
				cancel_task(self._active_thread)
				self._active_thread = nil
			end

			-- clear our dependencies, because we're starting a new computation that may not rely on our old dependencies
			table.clear(self._session_used)

			self.cached_value = self._pending_value
			self._old_value = self._pending_value

			-- start computation
			schedule_task_immediate(handle_eventual_computation, self)

			return not is_similar(self._old_value, self.cached_value)
		end,
	}),
})

const function generate_callbacks<T, S>(eventual: Self<T, S>): (state.Use, (any) -> ())
	const session_used = eventual._session_used

	const function use(target: state.UsedAs<T>): T
		if cast_to_state(target) ~= nil then
			depend(eventual, target)

			session_used[target] = true
		end

		return peek(target)
	end

	const function become(target_value: T)
		const old_value = eventual.cached_value

		eventual._old_value = old_value
		eventual.cached_value = target_value

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

const function destroy_eventual<T, S>(eventual: Self<T, S>)
	if eventual._active_thread ~= nil then
		cancel_task(eventual._active_thread)
	end

	eventual._session_used = nil

	cleanup(eventual._inner_scope)
	eventual._inner_scope = nil
end

const function Eventual<T, S>(
	scope: memory.Scope<S>,
	processor: async.EventualProcessor<S, T>,
	pending_value: T
): async.Eventual<T>
	const new_eventual: Self<T, S> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		cached_value = pending_value,
		_pending_value = pending_value,
		_old_value = nil,

		_is_becoming = false,
		_session_used = {},
		_inner_scope = nil,
		_processor = processor,
	}, CLASS_MT) :: any

	new_eventual._use, new_eventual._become = generate_callbacks(new_eventual)

	const oldest_task = destructor(new_eventual, destroy_eventual)
	new_eventual._oldest_task = oldest_task
	table.insert(scope, oldest_task)

	evaluate(new_eventual, true)

	return new_eventual
end

return Eventual
