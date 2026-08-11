--!native
--!optimize 2

const function channel_srgb_to_linear(channel: number): number
	if channel < 0.04045 then
		return channel / 12.92
	end

	return ((channel + 0.055) / 1.055) ^ 2.4
end

const function channel_linear_to_srgb(channel: number): number
	if channel <= 0.0031308 then
		return channel * 12.92
	end

	return (1.055 * channel ^ (1 / 2.4)) - 0.055
end

--- Maps a colour from the `sRGB` space into the `Linear RGB` space.
const function srgb_to_linear(srgb: vector): vector
	return vector.create(channel_srgb_to_linear(srgb.x), channel_srgb_to_linear(srgb.y), channel_srgb_to_linear(srgb.z))
end

--- Maps a colour from the `Linear RGB` space into the `sRGB` space.
const function linear_to_srgb(lrgb: vector): vector
	return vector.create(channel_linear_to_srgb(lrgb.x), channel_linear_to_srgb(lrgb.y), channel_linear_to_srgb(lrgb.z))
end

return {
	srgb_to_linear = srgb_to_linear,
	linear_to_srgb = linear_to_srgb,
}
