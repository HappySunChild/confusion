--!strict
--!native
--!optimize 2

const composition = require("../types")

const LINEAR: composition.Space = {
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

return LINEAR
