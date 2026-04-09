local Oklab = require("../colour/Oklab")

local function lerp_type<T>(a: T, b: T, alpha: number): T
	local data_type = typeof(a)

	if typeof(b) == data_type then
		if data_type == "number" then
			return math.lerp(a :: number, b :: number, alpha)
		elseif data_type == "vector" then
			return vector.lerp(a :: vector, b :: vector, alpha)
		elseif data_type == "Color3" then
			local a_vec = vector.create(a.R, a.G, a.B)
			local b_vec = vector.create(b.R, b.G, b.B)

			local ok_from = Oklab.from_srgb_to_oklab(a_vec)
			local ok_target = Oklab.from_srgb_to_oklab(b_vec)

			local ok_result = Oklab.from_oklab_to_srgb(vector.lerp(ok_from, ok_target, alpha))

			return Color3.new(ok_result.x, ok_result.y, ok_result.z)
		elseif data_type == "Vector3" then
			return (a :: Vector3):lerp(b :: Vector3, alpha)
		elseif data_type == "Vector2" then
			return (a :: Vector2):lerp(b :: Vector2, alpha)
		elseif data_type == "CFrame" then
			return (a :: CFrame):lerp(b :: CFrame, alpha)
		elseif data_type == "UDim" then
			return UDim.new(
				math.lerp((a :: UDim).Scale, (b :: UDim).Scale, alpha),
				math.lerp((a :: UDim).Offset, (b :: UDim).Offset, alpha)
			)
		elseif data_type == "UDim2" then
			return (a :: UDim2):Lerp(b :: UDim2, alpha)
		end
	end

	return if alpha < 0.5 then a else b
end

return lerp_type
