const motion = require("../motion/types")

const spring_coefficients = require("./spring_coefficients")

const function spring_mover(damping: number, speed: number)
	return function(goal: { number }): motion.Mover
		return function(initial_values: { { number } }): motion.Curve
			const initial_displacement = initial_values[1]
			const spring_count = #initial_displacement
			const initial_velocity = initial_values[2] or table.create(spring_count, 0)

			return function(time_elapsed: number)
				const pos_pos, pos_vel, vel_pos, vel_vel = spring_coefficients(time_elapsed, damping, speed)
				const displacement = table.create(spring_count, 0)
				const velocity = table.create(spring_count, 0)

				for index = 1, spring_count do
					const start_p = initial_displacement[index]
					const target_p = goal[index] -- TODO: not this
					const start_v = initial_velocity[index]
					const start_d = start_p - target_p
					local latest_d = start_d * pos_pos + start_v * pos_vel
					local latest_v = start_d * vel_pos + start_v * vel_vel

					if latest_d ~= latest_d or latest_v ~= latest_v then
						latest_d, latest_v = 0, 0
					end

					const latest_p = latest_d + target_p

					displacement[index] = latest_p
					velocity[index] = latest_v
				end

				return { displacement, velocity }
			end
		end
	end
end

return spring_mover
