local nicknames = require("./nicknames")

local function name_of(x: unknown, default: string)
	local nickname = nicknames[x]

	if type(nickname) == "string" then
		return nickname
	end

	if type(x) == "table" then
		x = x :: { [any]: any }

		if type(x.name) == "string" then
			return x.name
		elseif type(x.kind) == "string" then
			return x.kind
		elseif type(x.type) == "string" then
			return x.type
		end
	end

	return default
end

return name_of
