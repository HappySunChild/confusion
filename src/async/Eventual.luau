const async = require("./types")
const graph = require("../core_graph/types")
const logging = require("../core_logging/types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const ExternalScheduler = require("../core_external/ExternalScheduler")
const cancel_task = ExternalScheduler.cancel_task
const schedule_task_immediate = ExternalScheduler.schedule_task_immediate

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error_nonfatal = ExternalLogger.log_error_nonfatal

const cast_to_state = require("../core_state/cast_to_state")
const change = require("../core_graph/change")
const cleanup = require("../core_memory/cleanup")
const depend = require("../core_graph/depend")
const derive_scope = require("../core_memory/derive_scope")
const destructor = require("../core_memory/destructor")
const evaluate = require("../core_graph/evaluate")
const is_similar = require("../core_state/is_similar")
const parse_error = require("../core_logging/parse_error")
const peek = require("../core_use/peek")

type Self<T, S> = async.Eventual<T> & {
	inner_scope: memory.Scope<S>,
	processor: async.EventualProcessor<S, T>,
	become: (T) -> T,
	use: state.Use,

	prev_value: T?,
	is_becoming: boolean,
	active_thread: thread?,

	session_used: { [graph.GraphNode]: true },
}

const function handle_eventual_computation<T, S>(eventual: Self<T, S>)
	eventual.active_thread = coroutine.running()

	const inner_scope = derive_scope(eventual.scope)

	const ok, err: logging.Error = xpcall(eventual.processor, parse_error, eventual.use, inner_scope, eventual.become)

	if ok then -- adopt computation scope, clean up old one
		cleanup(eventual.inner_scope)
		eventual.inner_scope = inner_scope
	else -- throw away computation scope, invalidated because computation errored
		cleanup(inner_scope)
		log_error_nonfatal(state.callback_error, err)
	end

	eventual.active_thread = nil
end

const function generate_eventual_callbacks<T, S>(eventual: Self<T, S>): (state.Use, (any) -> ())
	const session_used = eventual.session_used

	const function use(target: state.UsedAs<T>): T
		if cast_to_state(target) ~= nil then
			depend(eventual, target)

			session_used[target] = true
		end

		return peek(target)
	end

	const function become(new_value: T): T
		const prev_value = eventual.cached_value

		eventual.prev_value = prev_value
		eventual.cached_value = new_value

		if eventual.validity == "busy" then
			return
		end

		eventual.is_becoming = true -- gross flag but it works

		change(eventual)

		for target in session_used do
			depend(eventual, target)
		end

		return new_value
	end

	return use, become
end

const function destroy_eventual<T, S>(eventual: Self<T, S>)
	if eventual.active_thread ~= nil then
		cancel_task(eventual._active_thread)
	end

	eventual.session_used = nil

	cleanup(eventual.inner_scope)
	eventual.inner_scope = nil
end

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Eventual",
		timeliness = "eager",

		is_pending = function<T, S>(self: Self<T, S>): boolean
			return self.active_thread ~= nil
		end,
		evaluate = function<T, S>(self: Self<T, S>): boolean
			if self.scope == nil then
				return false
			end

			-- calling `become` causes the Eventual to be reevaluated, but we don't want to completely reevaluate everything
			if self.is_becoming then
				self.is_becoming = false

				return not is_similar(self.prev_value, self.cached_value)
			end

			-- cancel any currently active computations
			if self.active_thread ~= nil then
				cancel_task(self.active_thread)
				self.active_thread = nil
			end

			-- clear our dependencies, because we're starting a new computation that may not rely on our old dependencies
			table.clear(self.session_used)

			self.cached_value = nil
			self.prev_value = nil

			-- start computation
			schedule_task_immediate(handle_eventual_computation, self)

			return not is_similar(self.prev_value, self.cached_value)
		end,
	}),
})

const function Eventual<T, S>(scope: memory.Scope<S>, processor: async.EventualProcessor<S, T>): async.Eventual<T>
	const new_eventual: Self<T, S> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},
		cached_value = nil,

		inner_scope = nil,
		processor = processor,
		prev_value = nil,
		is_becoming = false,
		active_thread = nil,
		session_used = {},
	}, CLASS_MT) :: any

	new_eventual.use, new_eventual.become = generate_eventual_callbacks(new_eventual)

	const oldest_task = destructor(new_eventual, destroy_eventual)
	new_eventual.oldest_task = oldest_task
	table.insert(scope, oldest_task)

	evaluate(new_eventual, true)

	return new_eventual
end

return Eventual
