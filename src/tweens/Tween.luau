--!strict

const chrono = require("../chrono/types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")
const tweens = require("./types")

const ExternalScheduler = require("../core_external/ExternalScheduler")
const get_delta_time = ExternalScheduler.get_delta_time

const Timer = require("../chrono/Timer")
const depend = require("../core_graph/depend")
const evaluate = require("../core_graph/evaluate")
const get_tween_alpha = require("./get_tween_alpha")
const get_tween_duration = require("./get_tween_duration")
const is_similar = require("../core_state/is_similar")
const lerp_type = require("../lerp/lerp_type")
const node_destructor = require("../core_graph/node_destructor")
const peek = require("../core_state/peek")

type Self<T> = tweens.Tween<T> & {
	goal: state.UsedAs<T>,
	info: state.UsedAs<tweens.TweenInfo>,

	active_start: T,
	active_finish: T,
	active_info: tweens.TweenInfo,
	active_duration: number,

	timer: chrono.Timer,
}

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Tween",
		timeliness = "eager",

		evaluate = function<T>(self: Self<T>)
			const goal = self.goal
			const info = self.info
			const timer = self.timer

			const new_finish = peek<<T>>(goal)
			const new_info = peek<<tweens.TweenInfo>>(info)

			depend(self, goal)
			depend(self, info)
			depend(self, timer)

			if self.active_finish ~= new_finish or (self.active_info ~= new_info and not timer.is_paused) then
				self.active_duration = get_tween_duration(new_info)
				self.active_start = self.cached_value
				self.active_finish = new_finish
				self.active_info = new_info
				timer:zero()
				timer:unpause()
			end

			local elapsed = peek<<number>>(timer)

			if elapsed == 0 then
				elapsed = get_delta_time()
			end

			const alpha = get_tween_alpha(new_info, elapsed)

			const old_value = self.cached_value
			const new_value = lerp_type(self.active_start, self.active_finish, alpha)

			self.cached_value = new_value :: T

			return not is_similar(old_value, new_value)
		end,
	}),
})

const function Tween<T>(scope: memory.Scope, goal: state.UsedAs<T>, info: state.UsedAs<tweens.TweenInfo>): tweens.Tween<T>
	const timer = Timer(scope)

	const new_tween: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},
		cached_value = peek(goal),

		goal = goal,
		info = info,

		active_start = peek(goal),
		active_finish = peek(goal),
		active_info = peek<<tweens.TweenInfo>>(info),
		active_duration = 0,

		timer = timer,
	}, CLASS_MT) :: any

	const oldest_task = node_destructor(new_tween)
	new_tween.oldest_task = oldest_task
	table.insert(scope, oldest_task)

	evaluate(new_tween, true)

	return new_tween
end

return Tween
