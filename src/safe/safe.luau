const function safe<Ok, Err>(callbacks: { try: () -> Ok, fallback: (err: unknown) -> Err }): Ok | Err
	const _, value = xpcall(callbacks.try, callbacks.fallback)

	return value
end

return safe
