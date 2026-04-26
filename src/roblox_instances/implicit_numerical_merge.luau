local function implicit_numerical_merge(tbl: { [any]: any }, target_key: any)
	local merged = { tbl[target_key] }

	for key, value in tbl do
		if type(key) == "number" then
			tbl[key] = nil
			table.insert(merged, value)
		end
	end

	tbl[target_key] = merged
end

return implicit_numerical_merge
