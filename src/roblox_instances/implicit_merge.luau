local rbx_instances = require("./types")

local function implicit_merge(properties: rbx_instances.Properties, target_key: any): { any }
	local implicit = {}

	for key, value in properties do
		if type(key) == "number" then
			table.insert(implicit, value)
		end
	end

	table.insert(implicit, properties[target_key])

	properties[target_key] = implicit
end

return implicit_merge
