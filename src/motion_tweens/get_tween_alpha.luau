local tweens = require("./types")

local function get_tween_alpha(info: tweens.TweenInfo, current_time: number)
	local tween_time, delay_time, repeat_count, reverses =
		info.time, info.delay_time, info.repeat_count, info.reverses

	local cycle_count = repeat_count + 1
	local cycle_duration = delay_time + tween_time

	if reverses then
		cycle_duration += tween_time
	end

	if current_time == math.huge then
		return 1
	end

	if current_time >= cycle_duration * cycle_count and cycle_count > 0 then
		return 1
	end

	local cycle_time = current_time % cycle_duration

	if cycle_time < delay_time then
		return 0
	end

	local tween_progress = (cycle_time - delay_time) / tween_time

	if tween_progress > 1 then
		tween_progress = 2 - tween_progress
	end

	return info.easing(tween_progress)
end

return get_tween_alpha
