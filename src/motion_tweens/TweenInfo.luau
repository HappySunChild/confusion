local tweens = require("./types")

local EasingStyles = require("./EasingStyles")

local CLASS = table.freeze({ type = "TweenInfo" })
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function TweenInfo(info: {
	easing_style: ((number) -> number)?,
	time: number?,
	delay_time: number?,
	reverses: boolean?,
	repeat_count: number?,
}): tweens.TweenInfo
	return setmetatable({
		easing_style = info.easing_style or EasingStyles.Linear.Out,
		time = info.time or 1,
		delay_time = info.delay_time or 0,
		reverses = info.reverses or false,
		repeat_count = info.repeat_count or 0,
	}, CLASS_METATABLE) :: any
end

return TweenInfo
