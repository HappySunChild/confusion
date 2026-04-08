local chrono = require("../chrono/types")
local memory = require("../core_memory/types")
local motion = require("./types")
local state = require("../core_state/types")

local ExternalScheduler = require("../core_external/ExternalScheduler")
local get_delta_time = ExternalScheduler.get_delta_time

local Timer = require("../chrono/Timer")
local change = require("../core_graph/change")
local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local evaluate = require("../core_graph/evaluate")
local is_similar = require("../core_state/is_similar")
local log_warn = require("../core_logging/log_warn")
local peek = require("../core_use/peek")

type Self<T> = {
	goal: state.UsedAs<T>,
	generator: state.UsedAs<motion.CurveGenerator<T>>,

	dynamics: { any },

	regenerate: boolean,

	active_goal: T,
	active_generator: motion.CurveGenerator<T>,
	active_curve: motion.AnimationCurve<T>,

	_timer: chrono.Timer,
} & motion.Motion<T>

local function sync_dynamics<T>(
	motion_obj: Self<T>,
	should_sleep: boolean,
	output_value: T,
	...: any
): (T, boolean)
	local dynamics = motion_obj.dynamics

	table.clear(dynamics)

	if output_value ~= output_value then
		local goal = motion_obj.active_goal

		log_warn(motion.animated_invalid_motion, output_value, goal)

		output_value = goal
	end

	dynamics[1] = output_value

	for i = 1, select("#", ...) do
		dynamics[i + 1] = select(i, ...)
	end

	return output_value, should_sleep
end

local CLASS = table.freeze({
	type = "state",
	kind = "Motion",
	timeliness = "eager",

	set_dynamic = function<T>(self: Self<T>, index: number, value: any)
		self.dynamics[index] = value
		self.regenerate = true

		change(self)
	end,
	set_dynamics = function<T>(self: Self<T>, new_dynamics: { any }, at_index: number?)
		table.move(new_dynamics, 1, #new_dynamics, at_index or 1, self.dynamics)
		self.regenerate = true

		change(self)
	end,
	get_dynamic = function<T>(self: Self<T>, index: number)
		return self.dynamics[index]
	end,
	get_dynamics = function<T>(self: Self<T>): { any }
		-- considered cloning, but i don't think it's worth it
		-- WARNING TO ANYONE USING THIS, DIRECTLY MODIFYING THE DYNAMICS TABLE
		-- IS VERY MUCH NOT RECOMMENDED, DO NOT DO IT UNLESS YOU KNOW WHAT YOU'RE DOING!!!
		return self.dynamics
	end,

	_evaluate = function<T>(self: Self<T>)
		local timer = self._timer
		local goal = self.goal
		local generator = self.generator

		local new_goal = peek(goal) :: T

		depend(self, goal)

		-- protect against NaN goals
		if new_goal ~= new_goal then
			log_warn(motion.animated_invalid_goal, new_goal)

			return false
		end

		local new_generator = peek(generator) :: motion.CurveGenerator<T>

		depend(self, generator)
		depend(self, timer)

		-- wake
		if
			new_goal ~= self.active_goal
			or new_generator ~= self.active_generator
			or self.regenerate
		then
			self.active_goal = new_goal
			self.active_generator = new_generator
			self.active_curve = generator(new_goal, unpack(self.dynamics))

			self.regenerate = false

			timer:zero()
			timer:unpause()
		end

		local elapsed = peek(timer)

		-- fix Motions following eachother
		if elapsed == 0 then -- usually means we got a new goal/curve generator
			elapsed = get_delta_time()
		end

		local old_value = self._cached_value :: any
		local new_value, should_sleep = sync_dynamics(self, self.active_curve(elapsed))

		self._cached_value = new_value

		if should_sleep then
			timer:pause()
		end

		return not is_similar(old_value, new_value)
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function Motion<T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	curve_generator: state.UsedAs<motion.CurveGenerator<T>>
): motion.Motion<T>
	local new_motion: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		_cached_value = nil, -- this is handled by the evaluate call below, so we can just leave this nil :3

		goal = goal,
		generator = curve_generator,

		dynamics = { peek(goal) },

		regenerate = false,
		active_goal = nil,
		active_generator = nil,
		active_move = nil,

		_timer = Timer(scope),
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_motion)

	new_motion._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	evaluate(new_motion, true)

	return new_motion
end

return Motion
