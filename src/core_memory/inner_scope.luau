const memory = require("./types")

const derive_scope = require("./derive_scope")

const function inner_scope<S, M>(existing: memory.Scope<S>, methods: M?): memory.Scope<S & M>
	const inner = derive_scope(existing, methods)

	table.insert(existing, inner)
	table.insert(inner, function()
		const index = table.find(existing, inner)

		if index ~= nil then
			table.remove(existing, index)
		end
	end)

	return inner
end

return inner_scope
