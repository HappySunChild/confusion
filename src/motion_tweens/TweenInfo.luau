local tweens = require("./types")

local EasingStyles = require("./EasingStyles")

local CLASS = table.freeze({
	type = "TweenInfo",
	time = 1,
	easing = EasingStyles.Linear.Out,
	repeat_count = 0,
	reverses = false,
	delay_time = 0,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function TweenInfo(
	time: number?,
	easing: ((number) -> number)?,
	repeat_count: number?,
	reverses: boolean?,
	delay_time: number?
): tweens.TweenInfo
	return setmetatable({
		time = time,
		easing = easing,
		repeat_count = repeat_count,
		reverses = reverses,
		delay_time = delay_time,
	}, CLASS_METATABLE) :: any
end

return TweenInfo
