const memory = require("../core_memory/types")
const motion = require("../motion/types")
const motion_tweens = require("./types")
const state = require("../core_state/types")

const Motion = require("../motion/Motion")
const get_tween_alpha = require("./get_tween_alpha")
const get_tween_duration = require("./get_tween_duration")
const lerp_type = require("../lerp/lerp_type")
const peek = require("../core_use/peek")

const function tween_mover<T>(info: state.UsedAs<motion_tweens.TweenInfo>)
	const curve_generator = function(target: T, start: T): motion.AnimationCurve<T>
		const active_info = peek(info) :: motion_tweens.TweenInfo
		const duration = get_tween_duration(active_info)

		const new_curve = function(elapsed: number): (boolean, T)
			const alpha = get_tween_alpha(active_info, elapsed)

			return elapsed >= duration, lerp_type(start, target, alpha)
		end

		return new_curve
	end

	return curve_generator
end

const function Tween<T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	info: state.UsedAs<motion_tweens.TweenInfo>
): motion.Motion<T>
	return Motion(scope, goal, tween_mover(info))
end

return Tween
