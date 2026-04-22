local memory = require("../core_memory/types")
local rbx_instances = require("./types")

local Children = require("./keys/Children")
local from_description = require("./from_description")

local function Describe(scope: memory.Scope, description: rbx_instances.ChildDescription)
	return from_description(scope, description, Children)
end

return Describe
