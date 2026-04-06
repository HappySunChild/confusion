@native
local function to_linear(channel: number): number
	if channel < 0.04045 then
		return channel / 12.92
	end

	return ((channel + 0.055) / 1.055) ^ 2.4
end

@native
local function to_srgb(channel: number): number
	if channel <= 0.0031308 then
		return channel * 12.92
	end

	return (1.055 * channel ^ (1 / 2.4)) - 0.055
end

return table.freeze({
	from_linear_to_srgb = @native function(rgb: vector): vector
		return vector.create(to_srgb(rgb.x), to_srgb(rgb.y), to_srgb(rgb.z))
	end,
	from_srgb_to_linear = @native function(srgb: vector): vector
		return vector.create(to_linear(srgb.x), to_linear(srgb.y), to_linear(srgb.z))
	end,
})
