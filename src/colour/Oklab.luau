local Linear = require("./Linear")

@native
local function from_linear_to_oklab(lrgb: vector): vector
	local r, g, b = lrgb.x, lrgb.y, lrgb.z

	local l = r * 0.4122214708 + g * 0.5363325363 + b * 0.0514459929
	local m = r * 0.2119034982 + g * 0.6806995451 + b * 0.1073969566
	local s = r * 0.0883024619 + g * 0.2817188376 + b * 0.6299787005

	local l_root = l ^ (1 / 3)
	local m_root = m ^ (1 / 3)
	local s_root = s ^ (1 / 3)

	return vector.create(
		l_root * 0.2104542553 + m_root * 0.7936177850 - s_root * 0.0040720468,
		l_root * 1.9779984951 - m_root * 2.4285922050 + s_root * 0.4505937099,
		l_root * 0.0259040371 + m_root * 0.7827717662 - s_root * 0.8086757660
	)
end

@native
local function from_oklab_to_linear(lab: vector, unclamped: boolean?): vector
	local L, a, b = lab.x, lab.y, lab.z

	local l_root = L + a * 0.3963377774 + b * 0.2158037573
	local m_root = L - a * 0.1055613458 - b * 0.0638541728
	local s_root = L - a * 0.0894841775 - b * 1.2914855480

	local l = l_root ^ 3
	local m = m_root ^ 3
	local s = s_root ^ 3

	local red = l * 4.0767416621 - m * 3.3077115913 + s * 0.2309699292
	local green = l * -1.2684380046 + m * 2.6097574011 - s * 0.3413193965
	local blue = l * -0.0041960863 - m * 0.7034186147 + s * 1.7076147010

	if unclamped ~= true then
		red = math.clamp(red, 0, 1)
		green = math.clamp(green, 0, 1)
		blue = math.clamp(blue, 0, 1)
	end

	return vector.create(red, green, blue)
end

return table.freeze({
	from_linear_to_oklab = from_linear_to_oklab,
	from_oklab_to_linear = from_oklab_to_linear,

	from_srgb_to_oklab = @native function(srgb: vector): vector
		return from_linear_to_oklab(Linear.from_srgb_to_linear(srgb))
	end,
	from_oklab_to_srgb = @native function(lab: vector, unclamped: boolean?): vector
		return Linear.from_linear_to_srgb(from_oklab_to_linear(lab, unclamped))
	end,
})
