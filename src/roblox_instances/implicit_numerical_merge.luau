local function implicit_numerical_merge(tbl: { [any]: any }, target_key: any)
	local merged = { tbl[target_key] }

	for key, value in tbl do
		if type(key) == "number" then
			tbl[key] = nil
			table.insert(merged, value)
		end
	end

	if #merged > 0 then
		tbl[target_key] = merged
	end
end

return implicit_numerical_merge
