const memory = require("../core_memory/types")
const motion = require("../motion/types")
const state = require("../core_state/types")

const Motion = require("../motion/Motion")
const pack_type = require("./pack_type")
const peek = require("../core_use/peek")
const spring_coefficients = require("./spring_coefficients")
const unpack_type = require("./unpack_type")

const EPSILON = 0.0001

const function spring_mover<T>(speed: state.UsedAs<number>, damping: state.UsedAs<number>): motion.CurveGenerator<T>
	local start_pos: { number } = {}
	local start_vel: { number } = {}

	const active_pos: { number } = {}
	local active_vel: { number } = {}
	local active_type: string = ""

	const curve_generator = function(
		target_position: T,
		initial_position: T,
		initial_velocity: { number }?
	): motion.AnimationCurve<T>
		const discontinuous = typeof(target_position) ~= active_type

		const target_pos = unpack_type(target_position)

		const spring_count = #target_pos

		if discontinuous then
			-- start_pos = table.clone(target_pos)
			-- active_pos = table.clone(target_pos)
			table.move(target_pos, 1, spring_count, 1, start_pos)
			table.move(target_pos, 1, spring_count, 1, active_pos)

			start_vel = table.create(spring_count, 0)
			active_vel = table.create(spring_count, 0)
		else
			-- start_pos = table.clone(active_pos)
			-- start_vel = table.clone(initial_velocity)
			table.move(active_pos, 1, spring_count, 1, start_pos)
			table.move(initial_velocity, 1, spring_count, 1, start_vel)
		end

		active_type = typeof(target_position)

		const new_curve = function(elapsed: number): (boolean, T, { number })
			local should_sleep = false
			local new_value

			if discontinuous then
				new_value = target_position
			elseif elapsed <= 0 then
				new_value = initial_position
			else
				const pos_pos, pos_vel, vel_pos, vel_vel = spring_coefficients(elapsed, peek(damping), peek(speed))

				local is_moving = false

				for index = 1, spring_count do
					const start_p: number = start_pos[index]
					const target_p: number = target_pos[index]
					const start_v: number = start_vel[index]
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

					active_pos[index] = latest_p
					active_vel[index] = latest_v
				end

				if not is_moving then
					for index = 1, spring_count do
						active_pos[index] = target_pos[index]
					end
				end

				should_sleep = not is_moving
				new_value = pack_type(active_type, active_pos)
			end

			return should_sleep, new_value, active_vel
		end

		return new_curve
	end

	return curve_generator
end

const function Spring<T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	speed: state.UsedAs<number>?,
	damping: state.UsedAs<number>?
): motion.Motion<T>
	return Motion(scope, goal, spring_mover(speed or 10, damping or 1))
end

return Spring
