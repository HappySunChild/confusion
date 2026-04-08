local Value = require("@fusion/core_state/Value")
local cast_to_state = require("@fusion/core_state/cast_to_state")
local cleanup = require("@fusion/core_memory/cleanup")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("cast_to_state", function(test: butler.Test)
		test("nonstate", function()
			local value_num = 10
			local value_str = "hello"
			local value_tble = {}

			expect(cast_to_state(value_num)):to_never_exist()
			expect(cast_to_state(value_str)):to_never_exist()
			expect(cast_to_state(value_tble)):to_never_exist()
		end)
		test("state", function()
			local scope = {}
			local new_value = Value(scope, 10)

			expect(cast_to_state(new_value)):to_exist():to_equal(new_value)

			cleanup(scope)
		end)
		test("dummy state", function()
			local dummy_state = { type = "state" }
			local dummy_state_with_meta = setmetatable({}, { __index = { type = "state" } })
			local non_state = { type = "not State" }
			local non_state_with_meta = setmetatable({}, { __index = { type = "not State" } })

			expect(cast_to_state(dummy_state)):to_exist():to_equal(dummy_state)
			expect(cast_to_state(dummy_state_with_meta)):to_exist():to_equal(dummy_state_with_meta)
			expect(cast_to_state(non_state)):to_never_exist()
			expect(cast_to_state(non_state_with_meta)):to_never_exist()
		end)
	end)
end
