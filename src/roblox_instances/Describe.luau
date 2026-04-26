local memory = require("../core_memory/types")
local rbx_instances = require("./types")

local Children = require("./keys/Children")
local instance_from_description = require("./instance_from_description")

local function Describe(scope: memory.Scope, description: rbx_instances.ChildDescription)
	return instance_from_description(scope, description, Children)
end

return Describe
