--!strict
--!native
--!optimize 2

const composition = require("../types")

const Oklab = require("../../colour/Oklab")
const srgb_to_oklab, oklab_to_srgb = Oklab.srgb_to_oklab, Oklab.oklab_to_srgb

const Linear = require("../../colour/Linear")
const srgb_to_lrgb, lrgb_to_srgb = Linear.srgb_to_linear, Linear.linear_to_srgb

const linear_space = require("../spaces/linear")

const LINEAR: composition.Compositor<vector> = {
	decompose = function(raw: vector): { number }
		return { raw.x, raw.y, raw.z }
	end,
	compose = function(vec: { number }): vector
		return vector.create(vec[1], vec[2], vec[3])
	end,
	space = linear_space,
}

const COLOUR_SRGB_AS_OKLAB: composition.Compositor<vector> = {
	decompose = function(raw: vector): { number }
		const lab = srgb_to_oklab(raw)
		return { lab.x, lab.y, lab.z }
	end,
	compose = function(vec: { number }): vector
		return oklab_to_srgb(vector.create(vec[1], vec[2], vec[3]))
	end,
	space = linear_space,
}

const COLOUR_SRGB_AS_LINEAR: composition.Compositor<vector> = {
	decompose = function(raw: vector): { number }
		const lrgb = srgb_to_lrgb(raw)
		return { lrgb.x, lrgb.y, lrgb.z }
	end,
	compose = function(vec: { number }): vector
		return lrgb_to_srgb(vector.create(vec[1], vec[2], vec[3]))
	end,
	space = linear_space,
}

return {
	linear = LINEAR,
	colour_oklab = COLOUR_SRGB_AS_OKLAB,
	colour_linear = COLOUR_SRGB_AS_LINEAR,

	default = LINEAR,
}
