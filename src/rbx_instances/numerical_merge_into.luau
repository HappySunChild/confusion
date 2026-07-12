const function numerical_merge_into(tbl: { [any]: any }, target_key: any)
	const merged = { tbl[target_key] }

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

return numerical_merge_into
