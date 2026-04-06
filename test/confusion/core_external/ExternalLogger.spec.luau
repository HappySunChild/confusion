local ExternalLogger = require("@fusion/core_external/ExternalLogger")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ExternalLogger", function(test: butler.Test)
		test("log_error always throws", function()
			ExternalLogger.set_logger({
				log_error = function() end,
			})
			expect(ExternalLogger.log_error):to_throw("")
			ExternalLogger.set_logger(nil)
			expect(ExternalLogger.log_error):to_throw("")
		end)
		test("log functions call logger functions", function()
			local log_warn_called = false
			local log_error_nonfatal_called = false
			local log_error_called = false
			ExternalLogger.set_logger({
				log_warn = function(message: string)
					expect(message:match("warn message")):to_exist()
					log_warn_called = true
				end,
				log_error_nonfatal = function(message: string)
					expect(message:match("error_nonfatal message")):to_exist()
					log_error_nonfatal_called = true
				end,
				log_error = function(message: string)
					expect(message:match("error message")):to_exist()
					log_error_called = true
				end,
			})

			expect(log_warn_called):to_equal(false)
			expect(log_error_called):to_equal(false)
			expect(log_error_nonfatal_called):to_equal(false)

			ExternalLogger.log_warn("warn message")
			ExternalLogger.log_error_nonfatal("error_nonfatal message")
			expect(ExternalLogger.log_error):to_never_throw_with(
				"Expectation not met",
				"error message"
			)

			expect(log_warn_called):to_equal(true)
			expect(log_error_called):to_equal(true)
			expect(log_error_nonfatal_called):to_equal(true)

			ExternalLogger.set_logger(nil) -- reset back to nil as to not break any other tests
		end)
	end)
end
