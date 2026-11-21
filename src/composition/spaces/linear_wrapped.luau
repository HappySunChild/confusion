--!strict
--!native
--!optimize 2

const composition = require("../types")

const function linear_wrapped(min: number, max: number): composition.Space
	const range = max - min
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
				position[index] = (component + relative_to[index]) % range + min
			end

			return position
		end,
	}
end

return linear_wrapped
