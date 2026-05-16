const Oklab = require("../colour/Oklab")
const oklab_from_srgb, oklab_to_srgb = Oklab.from_srgb, Oklab.to_srgb

const function lerp_type<T>(a: T, b: T, alpha: number): T
	const data_type = typeof(a)

	if typeof(b) == data_type then
		if data_type == "number" then
			return math.lerp(a :: number, b :: number, alpha)
		elseif data_type == "vector" then
			return vector.lerp(a :: vector, b :: vector, alpha)
		elseif data_type == "Color3" then
			const oklab_from = oklab_from_srgb(vector.create(a.R, a.G, a.B))
			const oklab_target = oklab_from_srgb(vector.create(b.R, b.G, b.B))
			const oklab_result =
				vector.clamp(oklab_to_srgb(vector.lerp(oklab_from, oklab_target, alpha)), vector.zero, vector.one)

			return Color3.new(oklab_result.x, oklab_result.y, oklab_result.z)
		elseif data_type == "Vector3" then
			return (a :: Vector3):Lerp(b :: Vector3, alpha)
		elseif data_type == "Vector2" then
			return (a :: Vector2):Lerp(b :: Vector2, alpha)
		elseif data_type == "CFrame" then
			return (a :: CFrame):Lerp(b :: CFrame, alpha)
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
