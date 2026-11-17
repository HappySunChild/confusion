const composition = require("../composition/types")
const motion = require("../motion/types")

const spring_coefficients = require("./spring_coefficients")

const function spring_mover(damping: number, speed: number): motion.Transition
	damping = damping or 1
	speed = speed or 10

	return function(goal_position: { number }, space: composition.Space): motion.Mover
		const to_displacement, to_position = space.to_displacement, space.to_position

		return function(initial_values: { { number } }): motion.Curve
			const initial_displacement = to_displacement(initial_values[1], goal_position)
			const spring_count = #initial_displacement
			const initial_velocity = initial_values[2] or table.create(spring_count, 0)

			return function(time_elapsed: number)
				const pos_pos, pos_vel, vel_pos, vel_vel = spring_coefficients(time_elapsed, damping, speed)
				const displacement = table.create(spring_count, 0)
				const velocity = table.create(spring_count, 0)

				for index = 1, spring_count do
					const start_p = initial_displacement[index]
					const start_v = initial_velocity[index]
					local latest_d = start_p * pos_pos + start_v * pos_vel
					local latest_v = start_p * vel_pos + start_v * vel_vel

					if latest_d ~= latest_d or latest_v ~= latest_v then
						latest_d, latest_v = 0, 0
					end

					displacement[index] = latest_d
					velocity[index] = latest_v
				end

				return { to_position(displacement, goal_position), velocity }
			end
		end
	end
end

return spring_mover
