--!nonstrict
--!native
--!optimize 2

const memory = require("./types")

const ExternalDebug = require("../core_external/ExternalDebug")
const untrack_scope = ExternalDebug.untrack_scope

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const ALREADY_DESTROYING: { [unknown]: true } = {}

--[[
	Cleans up the chores passed in as the arguments.
	A chore can be any of the following:
	- a Roblox Instance - will be destroyed
	- a Roblox RBXScriptConnection - will be disconnected
	- a function - will be ran
	- an array - `cleanup` will be called on each item
	- a table with a `Destroy` or `destroy` function - will be called
	- a table with a `Disconnect` or `disconnect` function - will be called
	
	Anything else passed in will be ignored.
]]
const function cleanup(chore: unknown?): ()
	if chore == nil then
		return
	end

	if ALREADY_DESTROYING[chore] ~= nil then
		log_error(memory.destroyed_twice)
	end

	ALREADY_DESTROYING[chore] = true

	if typeof(chore) == "Instance" then -- Roblox Instances
		(chore :: Instance):Destroy()
	elseif typeof(chore) == "RBXScriptConnection" then -- Roblox Connections
		(chore :: RBXScriptConnection):Disconnect()
	elseif type(chore) == "function" then -- callback functions
		(chore :: () -> ())()
	elseif type(chore) == "table" then
		const c = chore :: { [any]: any }

		if c[1] ~= nil then -- scope/array of chores
			for i = #c, 1, -1 do
				cleanup(c[i])

				c[i] = nil
			end

			untrack_scope(c)
		elseif type(c.destroy) == "function" then -- :destroy method
			c.destroy()
		elseif type(c.Destroy) == "function" then -- :Destroy method
			c:Destroy()
		elseif type(c.disconnect) == "function" then -- :disconnect method
			c:disconnect()
		elseif type(c.Disconnect) == "function" then -- :Disconnect method
			c:Disconnect()
		end
	end

	ALREADY_DESTROYING[chore] = nil
end

return cleanup
