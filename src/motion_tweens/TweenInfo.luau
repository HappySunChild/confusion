const motion_tweens = require("./types")

const easing_styles = require("./easing_styles")

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "TweenInfo",
		time = 1,
		easing = easing_styles.Linear.Out,
		repeat_count = 0,
		reverses = false,
		delay_time = 0,
	}),
})

const function TweenInfo(
	time: number?,
	easing: ((number) -> number)?,
	repeat_count: number?,
	reverses: boolean?,
	delay_time: number?
): motion_tweens.TweenInfo
	return setmetatable({
		time = time,
		easing = easing,
		repeat_count = repeat_count,
		reverses = reverses,
		delay_time = delay_time,
	}, CLASS_MT) :: any
end

return TweenInfo
