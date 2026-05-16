local global_version = 0

const function next_version()
	global_version += 1
	return global_version
end

return next_version
