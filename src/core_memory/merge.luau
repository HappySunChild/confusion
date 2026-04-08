local function merge(
	overwrite: boolean,
	into: { [unknown]: unknown },
	...: { [unknown]: unknown }
)
	local sets = { ... }

	for _, set in sets do
		for key, value in set do
			if overwrite or into[key] == nil then
				into[key] = value
			end
		end
	end

	return into
end

return merge
