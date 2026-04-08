local tweens = require("./types")

local function get_tween_alpha(info: tweens.TweenInfo, current_time: number)
	local cycle_count = info.repeat_count + 1
	local cycle_duration = info.delay_time + info.time

	if info.reverses then
		cycle_duration += info.time
	end

	if current_time == math.huge then
		return 1
	end

	if current_time >= cycle_duration * cycle_count and cycle_count > 0 then
		return 1
	end

	local cycle_time = current_time % cycle_duration

	if cycle_time < info.delay_time then
		return 0
	end

	local tween_progress = (cycle_time - info.delay_time) / info.time

	if tween_progress > 1 then
		tween_progress = 2 - tween_progress
	end

	return info.easing_style(tween_progress)
end

return get_tween_alpha
