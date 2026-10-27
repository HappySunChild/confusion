--!strict
--!native
--!optimize 2

const chrono = require("../chrono/types")
const memory = require("../core_memory/types")
const motion = require("./types")
const state = require("../core_state/types")

const ExternalScheduler = require("../core_external/ExternalScheduler")
const get_delta_time = ExternalScheduler.get_delta_time

const Timer = require("../chrono/Timer")
const change = require("../core_graph/change")
const depend = require("../core_graph/depend")
const evaluate = require("../core_graph/evaluate")
const is_similar = require("../core_state/is_similar")
const node_destructor = require("../core_graph/node_destructor")
const peek = require("../core_state/peek")

const SETTLED_EPSILON = 1e-4

const function determine_has_settled(jet: { { number } }): boolean
	for i, differential_shape in jet do
		if i == 1 then -- skip displacement/position
			continue
		end

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
	compositor: motion.Compositor<T>,

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
			self.derivatives[1] = self.compositor.decompose(new_displacement)
			self.refresh = true
			change(self)
		end,
		set_velocity = function<T>(self: Self<T>, new_velocity: T)
			self.derivatives[2] = self.compositor.decompose(new_velocity)
			self.refresh = true
			change(self)
		end,

		get_displacement = function<T>(self: Self<T>): T
			return self.compositor.compose(self.derivatives[1])
		end,
		get_velocity = function<T>(self: Self<T>): T
			return self.compositor.compose(self.derivatives[2])
		end,

		evaluate = function(self: Self<unknown>): boolean
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

			if determine_has_settled(new_derivatives) then
				timer:pause()
			end

			const old_value = self.cached_value
			const new_value = self.compositor.compose(new_derivatives[1])

			self.cached_value = new_value

			return not is_similar(old_value, new_value)
		end,
	}),
})

const function Motion<T>(
	scope: memory.Scope,
	mover: state.UsedAs<motion.Mover>,
	compositor: motion.Compositor<T>,
	initial_values: { T }?
): motion.Motion<T>
	const initial_derivatives = {}

	if initial_values ~= nil then
		for index, value in initial_values do
			initial_derivatives[index] = compositor.decompose(value)
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
		compositor = compositor,

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
