const nicknames = require("./nicknames")

const function name_of(x: unknown, default: string)
	const nickname = nicknames[x]

	if type(nickname) == "string" then
		return nickname
	end

	if type(x) == "table" then
		if type((x :: { [any]: any }).name) == "string" then
			return (x :: { [any]: any }).name
		elseif type((x :: { [any]: any }).kind) == "string" then
			return (x :: { [any]: any }).kind
		elseif type((x :: { [any]: any }).type) == "string" then
			return (x :: { [any]: any }).type
		end
	end

	return default
end

return name_of
