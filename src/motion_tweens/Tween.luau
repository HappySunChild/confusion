local memory = require("../core_memory/types")
local motion = require("../motion/types")
local state = require("../core_state/types")
local tweens = require("./types")

local Motion = require("../motion/Motion")
local get_tween_alpha = require("./get_tween_alpha")
local get_tween_duration = require("./get_tween_duration")
local lerp_type = require("../lerp/lerp_type")
local peek = require("../core_use/peek")

local function TweenMover<T>(info: state.UsedAs<tweens.TweenInfo>)
	local curve_generator = function(target: T, start: T): motion.AnimationCurve<T>
		local active_info = peek(info) :: tweens.TweenInfo
		local duration = get_tween_duration(active_info)

		local new_curve = function(elapsed: number): (boolean, T)
			local alpha = get_tween_alpha(active_info, elapsed)

			return elapsed >= duration, lerp_type(start, target, alpha)
		end

		return new_curve
	end

	return curve_generator
end

local function Tween<T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	info: state.UsedAs<tweens.TweenInfo>
): motion.Motion<T>
	return Motion(scope, goal, TweenMover(info))
end

return Tween
