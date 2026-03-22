local ExternalDebug = require("@fusion/core_external/ExternalDebug")
local cleanup = require("@fusion/core_memory/cleanup")
local scoped = require("@fusion/core_memory/scoped")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ExternalDebug", function(test: butler.Test)
		test("debugger starts and stops", function()
			local debugger_a_active = false
			local debugger_b_active = false

			local debugger_a = {
				start_debugging = function()
					debugger_a_active = true
				end,
				stop_debugging = function()
					debugger_a_active = false
				end,
			}
			local debugger_b = {
				start_debugging = function()
					debugger_b_active = true
				end,
				stop_debugging = function()
					debugger_b_active = false
				end,
			}

			expect(debugger_a_active):to_equal(false)
			expect(debugger_b_active):to_equal(false)

			ExternalDebug.set_debugger(debugger_a)

			expect(debugger_a_active):to_equal(true)
			expect(debugger_b_active):to_equal(false)

			ExternalDebug.set_debugger(debugger_b)

			expect(debugger_a_active):to_equal(false)
			expect(debugger_b_active):to_equal(true)

			ExternalDebug.set_debugger(nil)

			expect(debugger_a_active):to_equal(false)
			expect(debugger_b_active):to_equal(false)
		end)
		test("scope tracking and untracking", function()
			local tracking = {}

			ExternalDebug.set_debugger({
				start_debugging = function() end,
				stop_debugging = function() end,
				track_scope = function(scope)
					tracking[scope] = true
				end,
				untrack_scope = function(scope)
					tracking[scope] = nil
				end,
			})

			expect(next(tracking)):to_never_exist()

			local scope = scoped()
			table.insert(scope, {}) -- insert so it counts as a scope during cleanup routine, which will call untrack_scope

			expect(tracking[scope]):to_equal(true)
			cleanup(scope)
			expect(tracking[scope]):to_never_exist()
		end)
	end)
end
