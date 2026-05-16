const Oklab = require("../colour/Oklab")
const oklab_to_srgb = Oklab.to_srgb

const function pack_type(data_type: string, array: { number }): unknown
	if data_type == "number" then
		return array[1]
	elseif data_type == "vector" then
		return vector.create(array[1], array[2], array[3])
	elseif data_type == "Color3" then
		const ok_result =
			vector.clamp(oklab_to_srgb(vector.create(array[1], array[2], array[3])), vector.zero, vector.one)

		return Color3.new(ok_result.x, ok_result.y, ok_result.z)
	elseif data_type == "Vector3" then
		return Vector3.new(array[1], array[2], array[3])
	elseif data_type == "Vector2" then
		return Vector3.new(array[1], array[2])
	elseif data_type == "UDim2" then
		return UDim2.new(array[1], math.round(array[2]), array[3], math.round(array[4]))
	elseif data_type == "UDim" then
		return UDim.new(array[1], math.round(array[2]))
	elseif data_type == "CFrame" then
		return CFrame.new(array[1], array[2], array[3])
			* CFrame.fromAxisAngle(Vector3.new(array[4], array[5], array[6]), array[7])
	end

	return nil
end

return pack_type
