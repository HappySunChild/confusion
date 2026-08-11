--!native
--!optimize 2

const Linear = require("./Linear")
const linear_to_srgb, srgb_to_linear = Linear.linear_to_srgb, Linear.srgb_to_linear

const L_COLUMN = vector.create(0.4122214708, 0.5363325363, 0.0514459929)
const M_COLUMN = vector.create(0.2119034982, 0.6806995451, 0.1073969566)
const S_COLUMN = vector.create(0.0883024619, 0.2817188376, 0.6299787005)

-- linear rgb operations

--- Maps a colour defined in the `Linear RGB` space into the `Oklab` space.
const function linear_to_oklab(lrgb: vector): vector
	const l_root = vector.dot(lrgb, L_COLUMN) ^ (1 / 3)
	const m_root = vector.dot(lrgb, M_COLUMN) ^ (1 / 3)
	const s_root = vector.dot(lrgb, S_COLUMN) ^ (1 / 3)

	return vector.create(
		l_root * 0.2104542553 + m_root * 0.7936177850 - s_root * 0.0040720468,
		l_root * 1.9779984951 - m_root * 2.4285922050 + s_root * 0.4505937099,
		l_root * 0.0259040371 + m_root * 0.7827717662 - s_root * 0.8086757660
	)
end

--- Maps a colour defined in the `Oklab` space into the `Linear RGB` space.
const function oklab_to_linear(lab: vector): vector
	const L, a, b = lab.x, lab.y, lab.z

	const root = vector.create(
		L + a * 0.3963377774 + b * 0.2158037573,
		L - a * 0.1055613458 - b * 0.0638541728,
		L - a * 0.0894841775 - b * 1.2914855480
	)

	const cubed = root * root * root

	const l = cubed.x
	const m = cubed.y
	const s = cubed.z

	return vector.create(
		l * 4.0767416621 - m * 3.3077115913 + s * 0.2309699292,
		l * -1.2684380046 + m * 2.6097574011 - s * 0.3413193965,
		l * -0.0041960863 - m * 0.7034186147 + s * 1.7076147010
	)
end

--- Interpolates between two `Linear RGB` colours using the `Oklab` space.
const function lerp_linear(lrgb_from: vector, lrgb_to: vector, alpha: number, clamped: boolean): vector
	const oklab_from = linear_to_oklab(lrgb_from)
	const oklab_to = linear_to_oklab(lrgb_to)
	const oklab_result = vector.lerp(oklab_from, oklab_to, alpha)

	if not clamped then
		return oklab_to_linear(oklab_result)
	end

	return oklab_to_linear(vector.clamp(oklab_result, vector.zero, vector.one))
end

-- srgb operations

--- Maps a colour defined in the `sRGB` space into the `Oklab` space.
const function srgb_to_oklab(srgb: vector): vector
	return linear_to_oklab(srgb_to_linear(srgb))
end

--- Maps a colour defined in the `Oklab` space into the `sRGB` space.
const function oklab_to_srgb(lab: vector): vector
	return linear_to_srgb(oklab_to_linear(lab))
end

--- Interpolates between two `sRGB` colours using the `Oklab` space.
const function lerp_srgb(srgb_from: vector, srgb_to: vector, alpha: number, clamped: boolean): vector
	const oklab_from = srgb_to_oklab(srgb_from)
	const oklab_to = srgb_to_oklab(srgb_to)
	const oklab_result = vector.lerp(oklab_from, oklab_to, alpha)

	if not clamped then
		return oklab_to_srgb(oklab_result)
	end

	return oklab_to_srgb(vector.clamp(oklab_result, vector.zero, vector.one))
end

return {
	linear_to_oklab = linear_to_oklab,
	oklab_to_linear = oklab_to_linear,
	lerp_linear = lerp_linear,

	srgb_to_oklab = srgb_to_oklab,
	oklab_to_srgb = oklab_to_srgb,
	lerp_srgb = lerp_srgb,
}
