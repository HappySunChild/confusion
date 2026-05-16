const motion_tweens = require("./types")

const function get_tween_duration(info: motion_tweens.TweenInfo)
	const repeat_count = info.repeat_count

	if repeat_count == -1 then
		return math.huge
	end

	const tween_time, delay_time, reverses = info.time, info.delay_time, info.reverses
	local duration = tween_time + delay_time

	if reverses then
		duration += tween_time
	end

	duration *= repeat_count + 1

	return duration
end

return get_tween_duration
