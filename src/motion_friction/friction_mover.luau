const motion = require("../motion/types")

const function friction_mover(decay_factor: number): motion.Mover
	const inv_log_decay_factor = 1 / math.log(decay_factor)

	return function(initial_values: { { number } }): motion.Curve
		const initial_displacement = initial_values[1]
		const dim = #initial_displacement
		const initial_velocity = initial_values[2] or table.create(dim, 0)

		return function(t: number)
			const displacement_vel_factor = (1 - decay_factor ^ -t) * inv_log_decay_factor
			const velocity_vel_factor = decay_factor ^ -t

			const displacement = table.create(dim, 0)
			const velocity = table.create(dim, 0)

			for index = 1, dim do
				displacement[index] = initial_displacement[index] + displacement_vel_factor * initial_velocity[index]
				velocity[index] = initial_velocity[index] * velocity_vel_factor
			end

			return { displacement, velocity }
		end
	end
end

return friction_mover
