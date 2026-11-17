const composition = require("../composition/types")
const motion = require("../motion/types")

const function tween_mover(easing_style: () -> ()): motion.Transition
	return function(goal_position: { number }, space: composition.Space): motion.Curve end
end
