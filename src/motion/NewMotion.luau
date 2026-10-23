const chrono = require("../chrono/types")
const memory = require("../core_memory/types")
const motion = require("./types")
const state = require("../core_state/types")

const Timer = require("../chrono/Timer")
const depend = require("../core_graph/depend")
const peek = require("../core_state/peek")

type Self<T> = {
	mover: state.UsedAs<motion.Mover>,
	timer: chrono.Timer,

	jet: { { number } },
	active_mover: motion.Mover,
	active_curve: motion.Curve,
} & motion.NewMotion<T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Motion",
		timeliness = "eager",

		evaluate = function(self: Self<unknown>)
			const timer = self.timer
			const mover = self.mover

			depend(self, mover)
			depend(self, timer)

			const new_mover = peek(mover)

			if self.active_mover ~= new_mover then
				self.active_mover = new_mover
				self.active_curve = new_mover(unpack(self.jet))

				timer:zero()
				timer:unpause()
			end

			const time_elapsed = peek(timer)

			const has_settled, new_jet = self.active_curve(time_elapsed)

			self.jet = new_jet

			if has_settled then
				timer:pause()
			end
		end,
	}),
})

const function Motion(
	scope: memory.Scope,
	mover: state.UsedAs<motion.Mover>,
	timer: chrono.Timer?
): motion.NewMotion<unknown>
	if timer == nil then
		timer = Timer(scope)
	end

	const new_motion = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},
		cached_value = nil,

		mover = mover,
		timer = timer,
		jet = {},
		active_mover = nil,
		active_curve = nil,
	}, CLASS_MT)

	return new_motion
end

return Motion
