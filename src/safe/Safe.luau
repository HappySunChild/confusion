local function Safe<Ok, Err>(callbacks: { try: () -> Ok, fallback: (err: unknown) -> Err }): Ok | Err
	local _, value = xpcall(callbacks.try, callbacks.fallback)

	return value
end

return Safe
