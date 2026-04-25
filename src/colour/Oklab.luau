local Linear = require("./Linear")
local linear_to_srgb = Linear.to_srgb
local linear_from_srgb = Linear.from_srgb

local L_COLUMN = vector.create(0.4122214708, 0.5363325363, 0.0514459929)
local M_COLUMN = vector.create(0.2119034982, 0.6806995451, 0.1073969566)
local S_COLUMN = vector.create(0.0883024619, 0.2817188376, 0.6299787005)

@native
local function from_linear_to_oklab(lrgb: vector): vector
	local l_root = vector.dot(lrgb, L_COLUMN) ^ (1 / 3)
	local m_root = vector.dot(lrgb, M_COLUMN) ^ (1 / 3)
	local s_root = vector.dot(lrgb, S_COLUMN) ^ (1 / 3)

	return vector.create(
		l_root * 0.2104542553 + m_root * 0.7936177850 - s_root * 0.0040720468,
		l_root * 1.9779984951 - m_root * 2.4285922050 + s_root * 0.4505937099,
		l_root * 0.0259040371 + m_root * 0.7827717662 - s_root * 0.8086757660
	)
end

@native
local function from_oklab_to_linear(lab: vector): vector
	local L, a, b = lab.x, lab.y, lab.z

	local root = vector.create(
		L + a * 0.3963377774 + b * 0.2158037573,
		L - a * 0.1055613458 - b * 0.0638541728,
		L - a * 0.0894841775 - b * 1.2914855480
	)

	local cubed = root * root * root

	local l = cubed.x
	local m = cubed.y
	local s = cubed.z

	return vector.create(
		l * 4.0767416621 - m * 3.3077115913 + s * 0.2309699292,
		l * -1.2684380046 + m * 2.6097574011 - s * 0.3413193965,
		l * -0.0041960863 - m * 0.7034186147 + s * 1.7076147010
	)
end

return table.freeze({
	from_linear = from_linear_to_oklab,
	to_linear = from_oklab_to_linear,

	from_srgb = @native function(srgb: vector): vector
		return from_linear_to_oklab(linear_from_srgb(srgb))
	end,
	to_srgb = @native function(lab: vector): vector
		return linear_to_srgb(from_oklab_to_linear(lab))
	end,
})
