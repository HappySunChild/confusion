--!native
--!optimize 2
local tweens = require("./types")

local PI = math.pi
local TAU = PI * 2
local HALF_PI = PI / 2

local abs = math.abs
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt

local new = table.freeze({
	Exponent = function(exponent: number): tweens.EasingStyle
		local b = 2 ^ (exponent - 1)

		return table.freeze({
			Out = function(x: number): number
				return 1 - (1 - x) ^ exponent
			end,
			In = function(x: number): number
				return x ^ exponent
			end,
			InOut = function(x: number): number
				return if x < 0.5
					then b * x ^ exponent
					else 1 - (-2 * x + 2) ^ exponent / 2
			end,
		})
	end,
	Overshoot = function(amplitude: number): tweens.EasingStyle
		local V0 = amplitude
		local V1 = amplitude + 1
		local V2 = amplitude * 1.525

		return table.freeze({
			Out = function(x: number): number
				return 1 + V1 * (x - 1) ^ 3 + V0 * (x - 1) ^ 2
			end,
			In = function(x: number): number
				return V1 * x ^ 3 - V0 * x ^ 2
			end,
			InOut = function(x: number): number
				return if x < 0.5
					then ((2 * x) ^ 2) * ((V2 + 1) * 2 * x - V2) / 2
					else ((2 * x - 2) ^ 2 * ((V2 + 1) * (x * 2 - 2) + V2) + 2) / 2
			end,
		})
	end,
	Elastic = function(
		period: number
	): tweens.EasingStyle -- https://devforum.roblox.com/t/does-anyone-know-the-formulas-for-elastic-easing/2819110/2
		local V0 = TAU / period

		return table.freeze({
			Out = function(x: number): number
				if x <= 0 then
					return 0
				end
				if x >= 1 then
					return 1
				end

				local shift = (3 - x) * period / 12
				return 2 ^ (-10 * x) * sin((-x - shift) * V0) + 1
			end,
			In = function(x: number): number
				if x <= 0 then
					return 0
				end
				if x >= 1 then
					return 1
				end

				local shift = (2 + x) * period / 12
				return -2 ^ (10 * (x - 1)) * sin((x - 1 - shift) * V0)
			end,
			InOut = function(x: number): number
				if x <= 0 then
					return 0
				end
				if x >= 1 then
					return 1
				end

				local shift = (1.5 - abs(x - 0.5)) * period / 6
				return if x < 0.5
					then -2 ^ (10 * (2 * x - 1)) * sin((2 * x - 1 - shift) * V0) * 0.5
					else 2 ^ (-10 * (2 * x - 1)) * sin((2 * x - 1 + shift) * V0) * -0.5
						+ 1
			end,
		})
	end,
})

local EasingStyles = table.freeze({
	Constant = table.freeze({
		Out = function(): number
			return 1
		end,
		In = function(): number
			return 0
		end,
		InOut = function(x: number): number
			return if x < 0.5 then 0 else 1
		end,
	}),
	Linear = table.freeze({
		Out = function(x: number): number
			return x
		end,
		In = function(x: number): number
			return x
		end,
		InOut = function(x: number): number
			return x
		end,
	}),
	Exponential = table.freeze({
		Out = function(x: number): number
			return if x == 1 then 1 else 1 - 2 ^ (-10 * x)
		end,
		In = function(x: number): number
			return if x == 0 then 0 else 2 ^ (10 * x - 10)
		end,
		InOut = function(x: number): number
			return if x == 0
				then 0
				elseif x == 1 then 1
				else if x < 0.5
					then 2 ^ (20 * x - 10) / 2
					else 2 - 2 ^ (-20 * x + 10) / 2
		end,
	}),
	Circular = table.freeze({
		Out = function(x: number): number
			return sqrt(1 - (x - 1) ^ 2)
		end,
		In = function(x: number): number
			return 1 - sqrt(1 - x ^ 2)
		end,
		InOut = function(x: number): number
			return if x < 0.5
				then 1 - sqrt(1 - (2 * x) ^ 2) / 2
				else (sqrt(1 - (-2 * x + 2) ^ 2) + 1) / 2
		end,
	}),
	Sine = table.freeze({
		Out = function(x: number): number
			return sin(x * HALF_PI)
		end,
		In = function(x: number): number
			return 1 - cos(x * HALF_PI)
		end,
		InOut = function(x: number): number
			return -(cos(x * PI) - 1) / 2
		end,
	}),

	Back = new.Overshoot(1),
	Elastic = new.Elastic(0.3),

	Quad = new.Exponent(2),
	Cubic = new.Exponent(3),
	Quart = new.Exponent(4),
	Quint = new.Exponent(5),

	new = new,
})

return EasingStyles
