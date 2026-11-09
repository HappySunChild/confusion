--!strict
--!native
--!optimize 2

const OKLAB_L_COLUMN = vector.create(0.4122214708, 0.5363325363, 0.0514459929)
const OKLAB_M_COLUMN = vector.create(0.2119034982, 0.6806995451, 0.1073969566)
const OKLAB_S_COLUMN = vector.create(0.0883024619, 0.2817188376, 0.6299787005)

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

--- Maps a colour defined in the `Linear RGB` space into the `Oklab` space.
const function linear_to_oklab(lrgb: vector): vector
	const l_root = vector.dot(lrgb, OKLAB_L_COLUMN) ^ (1 / 3)
	const m_root = vector.dot(lrgb, OKLAB_M_COLUMN) ^ (1 / 3)
	const s_root = vector.dot(lrgb, OKLAB_S_COLUMN) ^ (1 / 3)

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

--- Maps a colour defined in the `sRGB` space into the `Oklab` space.
const function srgb_to_oklab(srgb: vector): vector
	return linear_to_oklab(srgb_to_linear(srgb))
end

--- Maps a colour defined in the `Oklab` space into the `sRGB` space.
const function oklab_to_srgb(lab: vector): vector
	return linear_to_srgb(oklab_to_linear(lab))
end

--- Interpolates between two `sRGB` colours using the `Oklab` space.
const function lerp_srgb_as_oklab(srgb_from: vector, srgb_to: vector, alpha: number, clamped: boolean): vector
	const oklab_from = srgb_to_oklab(srgb_from)
	const oklab_to = srgb_to_oklab(srgb_to)
	const oklab_result = vector.lerp(oklab_from, oklab_to, alpha)

	if not clamped then
		return oklab_to_srgb(oklab_result)
	end

	return oklab_to_srgb(vector.clamp(oklab_result, vector.zero, vector.one))
end

return {
	srgb_to_linear = srgb_to_linear,
	linear_to_srgb = linear_to_srgb,

	linear_to_oklab = linear_to_oklab,
	oklab_to_linear = oklab_to_linear,

	srgb_to_oklab = srgb_to_oklab,
	oklab_to_srgb = oklab_to_srgb,
	lerp_srgb_as_oklab = lerp_srgb_as_oklab,
}
