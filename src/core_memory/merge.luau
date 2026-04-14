local function merge(into: { [unknown]: unknown }, ...: { [unknown]: unknown })
	for _, set in { ... } do
		for key, value in set do
			into[key] = value
		end
	end

	return into
end

return merge
