--!strict
--!native
--!optimize 2

const chrono = require("../chrono/types")
const memory = require("../core_memory/types")
const springs = require("./types")
const state = require("../core_state/types")

const ExternalScheduler = require("../core_external/ExternalScheduler")
const get_delta_time = ExternalScheduler.get_delta_time

const ExternalLogger = require("../core_external/ExternalLogger")
const log_warn, log_error = ExternalLogger.log_warn, ExternalLogger.log_error

const Timer = require("../chrono/Timer")
const change = require("../core_graph/change")
const depend = require("../core_graph/depend")
const evaluate = require("../core_graph/evaluate")
const is_similar = require("../core_state/is_similar")
const node_destructor = require("../core_graph/node_destructor")
const pack_type = require("./pack_type")
const peek = require("../core_state/peek")
const spring_coefficients = require("./spring_coefficients")
const unpack_type = require("./unpack_type")

const EPSILON = 0.001

type Self<T> = springs.Spring<T> & {
	goal: state.UsedAs<T>,
	speed: state.UsedAs<number>,
	damping: state.UsedAs<number>,

	target_pos: { number },
	start_pos: { number },
	start_vel: { number },
	active_pos: { number },
	active_vel: { number },
	active_type: string,
	active_goal: T,
	active_speed: number,
	active_damping: number,
	spring_count: number,

	timer: chrono.Timer,
}

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Spring",
		timeliness = "eager",

		set_position = function<T>(self: Self<T>, new_position: T)
			evaluate(self)

			const new_type = typeof(new_position)

			if new_type ~= self.active_type then
				log_error("TODO")
			end

			self.start_pos = unpack_type(new_position)
			self.timer:unpause()

			change(self)
		end,
		set_velocity = function<T>(self: Self<T>, new_velocity: T)
			evaluate(self)

			const new_type = typeof(new_velocity)

			if new_type ~= self.active_type then
				log_error("TODO")
			end

			self.start_vel = unpack_type(new_velocity)

			self.timer:zero()
			self.timer:unpause()

			change(self)
		end,
		add_velocity = function<T>(self: Self<T>, delta: T)
			evaluate(self)

			const delta_type = typeof(delta)

			if delta_type ~= self.active_type then
				log_error("TODO")
			end

			const delta_array = unpack_type(delta)

			for index, component_delta in delta_array do
				self.active_vel[index] += component_delta
			end

			self.timer:zero()
			self.timer:unpause()

			change(self)
		end,
		evaluate = function<T>(self: Self<T>): boolean
			const goal = self.goal
			const speed = self.speed
			const damping = self.damping
			const timer = self.timer

			const new_goal = peek<<T>>(goal)
			const new_speed = peek<<number>>(speed)
			const new_damping = peek<<number>>(damping)

			depend(self, goal)
			depend(self, speed)
			depend(self, damping)
			depend(self, timer)

			const discontinuous = self.active_type ~= typeof(new_goal)

			if
				discontinuous
				or new_goal ~= self.active_goal
				or new_speed ~= self.active_speed
				or new_damping ~= self.active_damping
			then
				const target_pos = unpack_type(new_goal)
				const spring_count = #target_pos

				if discontinuous then
					table.move(target_pos, 1, spring_count, 1, self.start_pos)
					table.move(target_pos, 1, spring_count, 1, self.active_pos)

					self.start_vel = table.create(spring_count, 0)
					self.active_vel = table.create(spring_count, 0)
				else
					table.move(self.active_pos, 1, spring_count, 1, self.start_pos)
					table.move(self.active_vel, 1, spring_count, 1, self.start_vel)
				end

				self.active_goal = new_goal
				self.active_speed = new_speed
				self.active_damping = new_damping
				self.target_pos = target_pos
				self.active_type = typeof(new_goal)
				self.spring_count = spring_count

				timer:zero()
				timer:unpause()
			end

			local elapsed = peek<<number>>(timer)

			if elapsed == 0 then
				elapsed = get_delta_time()
			end

			const pos_pos, pos_vel, vel_pos, vel_vel =
				spring_coefficients(elapsed, peek<<number>>(damping), peek<<number>>(speed))

			local is_moving = false

			for index = 1, self.spring_count do
				const start_p = self.start_pos[index]
				const target_p = self.target_pos[index]
				const start_v = self.start_vel[index]
				const start_d = start_p - target_p
				local latest_d = start_d * pos_pos + start_v * pos_vel
				local latest_v = start_d * vel_pos + start_v * vel_vel

				if latest_d ~= latest_d or latest_v ~= latest_v then
					latest_d, latest_v = 0, 0
				end

				if not is_moving and (math.abs(latest_d) > EPSILON or math.abs(latest_v) > EPSILON) then
					is_moving = true
				end

				const latest_p = latest_d + target_p

				self.active_pos[index] = latest_p
				self.active_vel[index] = latest_v
			end

			if not is_moving then
				for index = 1, self.spring_count do
					self.active_pos[index] = self.target_pos[index]
				end
			end

			const old_value = self.cached_value
			const new_value = pack_type(self.active_type, self.active_pos)

			if not is_moving then
				timer:pause()
			end

			return is_similar(old_value, new_value)
		end,
	}),
})

const function Spring<T>(scope: memory.Scope, goal: state.UsedAs<T>, speed: state.UsedAs<T>?, damping: state.UsedAs<T>?)
	speed = speed or 10
	damping = damping or 1

	const timer = Timer(scope)

	const new_spring: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},
		cached_value = nil,

		goal = goal,
		speed = speed,
		damping = damping,

		target_pos = {},
		start_pos = {},
		start_vel = {},
		active_pos = {},
		active_vel = {},
		active_type = "",
		active_goal = nil,
		active_speed = peek(speed),
		active_damping = peek(damping),
		spring_count = 0,

		timer = timer,
	}, CLASS_MT) :: any

	const oldest_task = node_destructor(new_spring)
	new_spring.oldest_task = oldest_task
	table.insert(scope, oldest_task)

	evaluate(new_spring, true)

	return new_spring
end

return Spring
