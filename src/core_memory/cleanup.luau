local memory = require("./types")

local ExternalDebug = require("../core_external/ExternalDebug")
local untrack_scope = ExternalDebug.untrack_scope

local log_error = require("../core_logging/log_error")

local ALREADY_DESTROYING: { [memory.Chore]: true } = {}

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
local function cleanup(chore: memory.Chore?)
	if chore == nil then
		return
	end

	if ALREADY_DESTROYING[chore] ~= nil then
		log_error(memory.destroyed_twice)
	end

	ALREADY_DESTROYING[chore] = true

	if typeof(chore) == "Instance" then -- Roblox Instances
		chore:Destroy()
	elseif typeof(chore) == "RBXScriptConnection" then -- Roblox Connections
		chore = chore :: RBXScriptConnection

		chore:Disconnect()
	elseif typeof(chore) == "function" then -- callback functions
		chore = chore :: () -> ()

		chore()
	elseif typeof(chore) == "table" then
		if chore[1] ~= nil then -- scope/array of chores
			chore = chore :: { memory.Chore }

			for i = #chore, 1, -1 do
				cleanup(chore[i])

				chore[i] = nil
			end

			untrack_scope(chore)
		elseif typeof(chore.destroy) == "function" then -- :destroy method
			chore:destroy()
		elseif typeof(chore.Destroy) == "function" then -- :Destroy method
			chore:Destroy()
		elseif typeof(chore.disconnect) == "function" then -- :disconnect method
			chore:disconnect()
		elseif typeof(chore.Disconnect) == "function" then -- :Disconnect method
			chore:Disconnect()
		end
	end

	ALREADY_DESTROYING[chore] = nil
end

return cleanup
