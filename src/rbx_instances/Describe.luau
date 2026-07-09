const memory = require("../core_memory/types")
const rbx_instances = require("./types")

const Children = require("./keys/Children")
const instance_from_description = require("./instance_from_description")

const function Describe(scope: memory.Scope, description: rbx_instances.ChildDescription)
	return instance_from_description(scope, description, Children)
end

return Describe
