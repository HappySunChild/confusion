--!strict
--!native
--!optimize 2

const HALF_PI = math.pi / 2

const DIFFERENTIAL_EASING_STYLES = {
	linear = function(x: number): ...number
		return x, 1
	end,
	constant = function(x: number): ...number
		return 1
	end,
	quad = function(x: number): ...number
		return 1 - (1 - x) ^ 2, 2 * (1 - x), -2
	end,
	cubic = function(x: number): ...number
		return 1 - (1 - x) ^ 3, 3 * (1 - x) ^ 2, -6 * (1 - x), 6
	end,
	quart = function(x: number): ...number
		return 1 - (1 - x) ^ 4, 4 * (1 - x) ^ 3, -12 * (1 - x) ^ 2, 24 * (1 - x), -24
	end,
	quint = function(x: number): ...number
		return 1 - (1 - x) ^ 5, 5 * (1 - x) ^ 4, -20 * (1 - x) ^ 3, 60 * (1 - x) ^ 2, -120 * (1 - x), 120
	end,
	sine = function(x: number): ...number
		return math.sin(x * HALF_PI),
			HALF_PI * math.cos(x * HALF_PI),
			0.25 * math.pi ^ 2 * -math.sin(x * HALF_PI),
			0.125 * math.pi ^ 3 * -math.cos(x * HALF_PI),
			0.0625 * math.pi ^ 4 * math.sin(x * HALF_PI),
			0.03125 * math.pi ^ 5 * math.cos(x * HALF_PI),
			0.015625 * math.pi ^ 6 * -math.sin(x * HALF_PI)
	end,
	exponential = function(x: number): ...number
		return 1 - 2 ^ (-10 * x),
			2 ^ (1 - x * 10) * 5 * math.log(2),
			2 ^ (2 - x * 10) * -25 * math.log(2) ^ 2,
			2 ^ (3 - x * 10) * 125 * math.log(2) ^ 3,
			2 ^ (4 - x * 10) * -625 * math.log(2) ^ 4,
			2 ^ (5 - x * 10) * 3125 * math.log(2) ^ 5,
			2 ^ (6 - x * 10) * -15625 * math.log(2) ^ 6
	end,
	circular = function(x: number): ...number
		return (-x * (x - 2)) ^ 0.5,
			(1 - x) / (-x * (x - 2)) ^ 0.5,
			-1 / (-x * (x - 2)) ^ 1.5,
			(3 - 3 * x) / (-x * (x - 2)) ^ 2.5,
			(15 - 24 * x + 12 * x ^ 2) / (-x * (x - 2)) ^ 3.5,
			(-105 + 225 * x - 180 * x ^ 2 + 60 * x ^ 3) / (-x * (x - 2)) ^ 4.5,
			(-945 + 2520 * x - 2700 * x ^ 2 + 1440 * x ^ 3 - 360 * x ^ 4) / (-x * (x - 2)) ^ 5.5
	end,
}

return DIFFERENTIAL_EASING_STYLES
