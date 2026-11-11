--!strict
--!native
--!optimize 2

const chrono = require("../chrono/types")
const memory = require("../core_memory/types")
const motion = require("./types")
const state = require("../core_state/types")

const ExternalScheduler = require("../core_external/ExternalScheduler")
const get_delta_time = ExternalScheduler.get_delta_time

const array_math = require("./array_math")
const array_add = array_math.add

const Timer = require("../chrono/Timer")
const change = require("../core_graph/change")
const depend = require("../core_graph/depend")
const evaluate = require("../core_graph/evaluate")
const is_similar = require("../core_state/is_similar")
const node_destructor = require("../core_graph/node_destructor")
const peek = require("../core_state/peek")

const SETTLED_EPSILON = 0.001

const function determine_has_settled(jet: { { number } }): boolean
	for i = 2, #jet do
		const differential_shape = jet[i]

		for _, component in differential_shape do
			if math.abs(component) >= SETTLED_EPSILON then
				return false
			end
		end
	end

	return true
end

type Self<T> = {
	mover: state.UsedAs<motion.Mover>,
	timer: chrono.Timer,
	compose: ({ number }) -> T,
	decompose: (T) -> { number },

	refresh: boolean,
	derivatives: { { number } },
	active_mover: motion.Mover,
	active_curve: motion.Curve,
} & motion.Motion<T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Motion",
		timeliness = "eager",

		set_displacement = function<T>(self: Self<T>, new_displacement: T)
			self.derivatives[1] = self.decompose(new_displacement)
			self.refresh = true
			change(self)
		end,
		set_velocity = function<T>(self: Self<T>, new_velocity: T)
			self.derivatives[2] = self.decompose(new_velocity)
			self.refresh = true
			change(self)
		end,

		impulse_velocity = function<T>(self: Self<T>, velocity: T)
			self.derivatives[2] = array_add(self.derivatives[2], self.decompose(velocity))
			self.refresh = true
			change(self)
		end,

		get_displacement = function<T>(self: Self<T>): T
			return self.compose(self.derivatives[1])
		end,
		get_velocity = function<T>(self: Self<T>): T
			return self.compose(self.derivatives[2])
		end,

		is_settled = function<T>(self: Self<T>): boolean
			return self.timer.is_paused
		end,

		evaluate = function<T>(self: Self<T>): boolean
			const timer = self.timer
			const mover = self.mover

			depend(self, mover)
			depend(self, timer)

			const new_mover = peek<<motion.Mover>>(mover)

			if self.active_mover ~= new_mover or self.refresh then
				self.refresh = false
				self.active_mover = new_mover
				self.active_curve = new_mover(self.derivatives)

				timer:zero()
				timer:unpause()
			end

			local current_elapsed = peek<<number>>(timer)

			if current_elapsed == 0 then
				current_elapsed = get_delta_time()
			end

			const new_derivatives = self.active_curve(current_elapsed)

			self.derivatives = new_derivatives

			const has_settled = determine_has_settled(new_derivatives)

			if has_settled then
				timer:pause()
			end

			const old_value = self.cached_value
			const new_value = self.compose(new_derivatives[1])

			self.cached_value = new_value

			-- not entirely sure about this has_settled being here, i'm only adding this because there's currently
			-- no way to consistently detect when a motion has gone to sleep
			return has_settled or not is_similar(old_value, new_value)
		end,
	}),
})

const function Motion<T>(
	scope: memory.Scope,
	mover: state.UsedAs<motion.Mover>,
	compositor: motion.Compositor<T>,
	initial_values: { T }?
): motion.Motion<T>
	const compose, decompose = compositor.compose, compositor.decompose

	const initial_derivatives = {}

	if initial_values ~= nil then
		for index, value in initial_values do
			initial_derivatives[index] = decompose(value)
		end

		initial_derivatives[1] = initial_derivatives[1] or {}
	end

	const new_motion: motion.Motion<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},
		cached_value = nil,

		mover = mover,
		timer = Timer(scope),
		compose = compose,
		decompose = decompose,

		refresh = false,
		derivatives = initial_derivatives,
		active_mover = nil,
		active_curve = nil,
	}, CLASS_MT) :: any

	const oldest_task = node_destructor(new_motion)
	new_motion.oldest_task = oldest_task
	table.insert(scope, oldest_task)

	evaluate(new_motion, true)

	return new_motion
end

return Motion
