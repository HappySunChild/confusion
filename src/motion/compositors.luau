--!strict
--!native
--!optimize 2

const motion = require("./types")
const spaces = require("./spaces")

const NUMBER_LINEAR: motion.Compositor<number> = {
	decompose = function(raw: number): { number }
		return { raw }
	end,
	compose = function(vec: { number }): number
		return vec[1]
	end,
	space = spaces.linear,
}
const VECTOR_LINEAR: motion.Compositor<vector> = {
	decompose = function(raw: vector): { number }
		return { raw.x, raw.y, raw.z }
	end,
	compose = function(vec: { number }): vector
		return vector.create(vec[1], vec[2], vec[3])
	end,
	space = spaces.linear,
}

return {
	number = {
		linear = NUMBER_LINEAR,
	},
	vector = {
		linear = VECTOR_LINEAR,
	},
}
