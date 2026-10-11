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
	elseif typeof(chore) == "function" then -- callback functions
		(chore :: () -> ())()
	elseif typeof(chore) == "table" then
		local chor = chore :: { [any]: any }

		if chor[1] ~= nil then -- scope/array of chores
			for i = #chor, 1, -1 do
				cleanup(chor[i])

				chor[i] = nil
			end

			untrack_scope(chor)
		elseif typeof(chor.destroy) == "function" then -- :destroy method
			chor:destroy()
		elseif typeof(chor.Destroy) == "function" then -- :Destroy method
			chor:Destroy()
		elseif typeof(chor.disconnect) == "function" then -- :disconnect method
			chor:disconnect()
		elseif typeof(chor.Disconnect) == "function" then -- :Disconnect method
			chor:Disconnect()
		end
	end

	ALREADY_DESTROYING[chore] = nil
end

return cleanup
