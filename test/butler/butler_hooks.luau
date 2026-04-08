export type HookMethod =
	| "before_test"
	| "after_test"
	| "before_unit"
	| "after_unit"
	| "before_units"
	| "after_units"
	| string
export type Hook<Keys = HookMethod> = { [Keys]: (...any) -> () }
export type ButlerHooks = { notify: (method_name: HookMethod, ...any) -> () }

local function butler_hooks(hooks: { Hook }?): ButlerHooks
	local new_butlerhooks = {
		notify = function(method_name: HookMethod, ...: any)
			if hooks == nil then
				return
			end

			for _, hook in hooks do
				local method = hook[method_name]

				if typeof(method) == "function" then
					method(...)
				end
			end
		end,
	}

	return new_butlerhooks
end

return butler_hooks
