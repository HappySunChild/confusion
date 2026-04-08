local Oklab = require("../colour/Oklab")

local function unpack_type(value: any): { number }
	local data_type = typeof(value)

	if data_type == "number" then
		return { value }
	elseif data_type == "vector" then
		return { value.x, value.y, value.z }
	elseif data_type == "Color3" then
		local lab = Oklab.from_srgb_to_oklab(value)

		return { lab.x, lab.y, lab.z }
	elseif data_type == "Vector3" then
		return { value.X, value.Y, value.Z }
	elseif data_type == "Vector2" then
		return { value.X, value.Y }
	elseif data_type == "UDim2" then
		return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
	elseif data_type == "UDim" then
		return { value.Scale, value.Offset }
	elseif data_type == "CFrame" then
		local axis, angle = value:ToAxisAngle()

		return { value.X, value.Y, value.Z, axis.X, axis.Y, axis.Z, angle }
	end

	return {}
end

return unpack_type
