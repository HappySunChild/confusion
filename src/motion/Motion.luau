local calc = require("../core_calc/types")
local chrono = require("../chrono/types")
local memory = require("../core_memory/types")
local motion = require("./types")

local ExternalScheduler = require("../core_external/ExternalScheduler")
local get_delta_time = ExternalScheduler.get_delta_time

local Timer = require("../chrono/Timer")
local change = require("../core_graph/change")
local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local evaluate = require("../core_graph/evaluate")
local is_similar = require("../core_calc/is_similar")
local log_warn = require("../core_logging/log_warn")
local peek = require("../core_use/peek")

type Self<T> = {
	_goal: calc.UsedAs<T>,
	_generator: calc.UsedAs<motion.MoveGenerator<T>>,

	_dynamics: { any },

	_regenerate: boolean?,

	_active_goal: T,
	_active_generator: motion.MoveGenerator<T>,
	_active_move: motion.AnimationMove<T>,

	_timer: chrono.Timer,
} & motion.Motion<T>

local function sync_dynamics<T>(
	motion_obj: Self<T>,
	should_sleep: boolean,
	output_value: T,
	...: any
): (T, boolean)
	local dynamics = motion_obj._dynamics

	table.clear(dynamics)

	if output_value ~= output_value then
		local goal = motion_obj._active_goal

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
	type = "State",
	kind = "Motion",
	timeliness = "eager",

	set_dynamic = function<T>(self: Self<T>, index: number, value: any)
		self._dynamics[index] = value
		self._regenerate = true

		change(self)
	end,
	set_dynamics = function<T>(self: Self<T>, dynamics: { any }, at_index: number?)
		table.move(dynamics, 1, #dynamics, at_index or 1, self._dynamics)
		self._regenerate = true

		change(self)
	end,
	get_dynamic = function<T>(self: Self<T>, index: number)
		return self._dynamics[index]
	end,
	get_dynamics = function<T>(self: Self<T>): { any }
		-- considered cloning, but i don't think it's worth it
		-- WARNING TO ANYONE USING THIS, DIRECTLY MODIFYING THE DYNAMICS TABLE
		-- IS VERY MUCH NOT RECOMMENDED, DO NOT DO IT UNLESS YOU KNOW WHAT YOU'RE DOING!!!
		return self._dynamics
	end,

	_evaluate = function<T>(self: Self<T>)
		local timer = self._timer
		local goal = self._goal
		local generator = self._generator

		local new_goal = peek(goal) :: T

		depend(self, goal)

		-- protect against NaN goals
		if new_goal ~= new_goal then
			log_warn(motion.animated_invalid_goal, new_goal)

			return false
		end

		local new_generator = peek(generator) :: motion.MoveGenerator<T>

		depend(self, generator)
		depend(self, timer)

		-- wake
		if
			new_goal ~= self._active_goal
			or new_generator ~= self._active_generator
			or self._regenerate == true
		then
			self._regenerate = nil

			self._active_goal = new_goal
			self._active_generator = new_generator
			self._active_move = generator(new_goal, unpack(self._dynamics))

			timer:zero()
			timer:unpause()
		end

		local elapsed = peek(timer) :: number

		-- fix Motions following eachother
		if elapsed == 0 then
			elapsed = get_delta_time()
		end

		local old_value = self._cached_value :: any
		local new_value, should_sleep = sync_dynamics(self, self._active_move(elapsed))

		self._cached_value = new_value

		if should_sleep then
			timer:pause()
		end

		return not is_similar(old_value, new_value)
	end,
})
local METATABLE = table.freeze({ __index = CLASS })

local function Motion<T>(
	scope: memory.Scope,
	goal: calc.UsedAs<T>,
	move_generator: calc.UsedAs<motion.MoveGenerator<T>>
): motion.Motion<T>
	local new_motion: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		_cached_value = nil, -- this is handled by the evaluate call below, so we can just leave this nil :3

		_goal = goal,
		_generator = move_generator,

		_dynamics = { peek(goal) },

		_regenerate = nil,
		_active_goal = nil,
		_active_generator = nil,
		_active_move = nil,

		_timer = Timer(scope),
	}, METATABLE) :: any

	table.insert(scope, destructor(new_motion))

	evaluate(new_motion, true)

	return new_motion
end

return Motion
