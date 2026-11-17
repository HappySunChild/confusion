--!strict
--!native
--!optimize 2

const tweens = require("./types")

const function sample(
	style: tweens.DifferentialEasingStyle,
	x: number,
	x_offset: number,
	y_offset: number,
	width: number,
	height: number
): { number }
	const inverse_width = 1 / width
	const samples = { style((x - x_offset) / width) }

	for derivative, sample in samples do
		samples[derivative] = sample * height * inverse_width ^ (derivative - 1)
			+ if derivative == 1 then y_offset else 0
	end

	return samples
end

const function sample_direction(
	style: tweens.DifferentialEasingStyle,
	direction: tweens.EasingDirection,
	x: number,
	x_offset: number,
	y_offset: number,
	width: number,
	height: number
): { number }
	if direction == "in" then
		x_offset += width
		y_offset += height
		width *= -1
		height *= -1
	elseif direction == "inout" then
		const flip = (x - x_offset) / width <= 0.5
		width /= 2
		height /= 2
		x_offset += width
		y_offset += height
		if flip then
			width *= -1
			height *= -1
		end
	end

	return sample(style, x, x_offset, y_offset, width, height)
end

const function sample_direction_reversing(
	style: tweens.DifferentialEasingStyle,
	direction: tweens.EasingDirection,
	reverse: boolean,
	x: number,
	x_offset: number,
	y_offset: number,
	width: number,
	height: number
): { number }
	if reverse then
		if (x - x_offset) / width > 0.5 then
			x += width
			width *= -1
		end
		width /= 2
	end

	return sample_direction(style, direction, x, x_offset, y_offset, width, height)
end

return sample_direction_reversing
