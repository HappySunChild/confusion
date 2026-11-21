--!strict
--!native
--!optimize 2

const composition = require("../types")

const linear_space = require("../spaces/linear")

const LINEAR: composition.Compositor<number> = {
	decompose = function(raw: number): { number }
		return { raw }
	end,
	compose = function(vec: { number }): number
		return vec[1]
	end,
	space = linear_space,
}

return {
	linear = LINEAR,
	default = LINEAR,
}
