const keyframes = require("./types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const destructor = require("../core_memory/destructor")
const evaluate_keyframes = require("./evaluate_keyframes")
const generic_use = require("../core_use/generic_use")
const is_similar = require("../core_state/is_similar")

type Self<T> = {
	alpha: state.UsedAs<number>,
	keyframes: { T },
	use: state.Use,
} & keyframes.Keyframes<T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Keyframes",
		timeliness = "lazy",

		evaluate = function<T>(self: Self<T>): boolean
			if self.scope == nil then
				return false
			end

			const use = self.use

			const old_value = self.cached_value
			const new_value = evaluate_keyframes(use(self.alpha), self.keyframes, use)

			self.cached_value = new_value

			return not is_similar(old_value, new_value)
		end,
	}),
})

const function Keyframes<T>(scope: memory.Scope, alpha: state.UsedAs<number>, keyframes: { T }): keyframes.Keyframes<T> | T
	const new_keyframes: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},
		cached_value = nil,

		alpha = alpha,
		keyframes = keyframes,
	}, CLASS_MT) :: any

	new_keyframes.use = generic_use(new_keyframes)

	const oldest_task = destructor(new_keyframes)
	new_keyframes.oldest_task = oldest_task
	table.insert(scope, oldest_task)

	return new_keyframes
end

return Keyframes
