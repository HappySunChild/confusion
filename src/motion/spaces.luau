const motion = require("./types")

const LINEAR_SPACE: motion.Space = {
	to_displacement = function(position: { number }, relative_to: { number }): { number }
		const displacement = table.create(#position, 0)

		for index, component in position do
			displacement[index] = component - relative_to[index]
		end

		return displacement
	end,
	to_position = function(displacement: { number }, relative_to: { number }): { number }
		const position = table.create(#displacement, 0)

		for index, component in displacement do
			position[index] = component + relative_to[index]
		end

		return position
	end,
}

const function linear_wrapped(minimum: number, maximum: number): motion.Space
	const range = maximum - minimum
	const half_range = range / 2

	return {
		to_displacement = function(position: { number }, relative_to: { number }): { number }
			const displacement = table.create(#position, 0)

			for index, component in position do
				displacement[index] = (component - relative_to[index] + half_range) % range - half_range
			end

			return displacement
		end,
		to_position = function(displacement: { number }, relative_to: { number }): { number }
			const position = table.create(#displacement, 0)

			for index, component in displacement do
				position[index] = (component + relative_to[index]) % range + minimum
			end

			return position
		end,
	}
end

return {
	linear = LINEAR_SPACE,
	linear_wrapped = linear_wrapped,

	degrees_unsigned = linear_wrapped(0, 360),
	degrees_signed = linear_wrapped(-180, 180),
	radians_unsigned = linear_wrapped(0, math.tau),
	radians_signed = linear_wrapped(-math.pi, math.pi),
}
