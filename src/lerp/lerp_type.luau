--!native
--!optimize 2

const Oklab = require("../colour/Oklab")
const oklab_lerp_srgb = Oklab.lerp_srgb

const Roblox = require("../colour/Roblox")
const to_vector, from_vector = Roblox.to_vector, Roblox.from_vector

const function lerp_type<T>(a: T, b: T, alpha: number): T
	const data_type = typeof(a)

	if typeof(b) == data_type then
		if data_type == "number" then
			return math.lerp(a :: number, b :: number, alpha)
		elseif data_type == "vector" then
			return vector.lerp(a :: vector, b :: vector, alpha)
		elseif data_type == "CFrame" then
			return (a :: CFrame):Lerp(b :: CFrame, alpha)
		elseif data_type == "Color3" then
			return from_vector(oklab_lerp_srgb(to_vector(a), to_vector(b), alpha, true))
		elseif data_type == "ColorSequence" then
			const from: ColorSequence, to: ColorSequence = a, b
			const from_keypoints, to_keypoints = from.Keypoints, to.Keypoints

			if #from_keypoints == #to_keypoints then
				const interpolated_keypoints = table.create(#from_keypoints)

				for index = 1, #from_keypoints do
					const from_keypoint, to_keypoint = from_keypoints[index], to_keypoints[index]

					interpolated_keypoints[index] = lerp_type(from_keypoint, to_keypoint, alpha)
				end

				return ColorSequence.new(interpolated_keypoints)
			end
		elseif data_type == "ColorSequenceKeypoint" then
			const from: ColorSequenceKeypoint, to: ColorSequenceKeypoint = a, b

			return ColorSequenceKeypoint.new(
				math.lerp(from.Time, to.Time, alpha),
				from_vector(oklab_lerp_srgb(to_vector(from), to_vector(to), alpha, true))
			)
		elseif data_type == "NumberRange" then
			const from: NumberRange, to: NumberRange = a, b

			return NumberRange.new(math.lerp(from.Min, to.Min, alpha), math.lerp(from.Max, to.Max, alpha))
		elseif data_type == "NumberSequence" then
			const from: NumberSequence, to: NumberSequence = a, b
			const from_keypoints, to_keypoints = from.Keypoints, to.Keypoints

			if #from_keypoints == #to_keypoints then
				const interpolated_keypoints = table.create(#from_keypoints)

				for index = 1, #from_keypoints do
					const from_keypoint, to_keypoint = from_keypoints[index], to_keypoints[index]

					interpolated_keypoints[index] = lerp_type(from_keypoint, to_keypoint, alpha)
				end

				return NumberSequence.new(interpolated_keypoints)
			end
		elseif data_type == "NumberSequenceKeypoint" then
			const from: NumberSequenceKeypoint, to: NumberSequenceKeypoint = a, b

			return NumberSequenceKeypoint.new(
				math.lerp(from.Time, to.Time, alpha),
				math.lerp(from.Value, to.Value, alpha),
				math.lerp(from.Envelope, to.Envelope, alpha)
			)
		elseif data_type == "Rect" then
			const from: Rect, to: Rect = a, b

			return Rect.new(from.Min:Lerp(to.Min, alpha), from.Max:Lerp(to.Max, alpha))
		elseif data_type == "UDim" then
			return UDim.new(
				math.lerp((a :: UDim).Scale, (b :: UDim).Scale, alpha),
				math.lerp((a :: UDim).Offset, (b :: UDim).Offset, alpha)
			)
		elseif data_type == "UDim2" then
			return (a :: UDim2):Lerp(b :: UDim2, alpha)
		elseif data_type == "Vector2" then
			return (a :: Vector2):Lerp(b :: Vector2, alpha)
		elseif data_type == "Vector3" then
			return (a :: Vector3):Lerp(b :: Vector3, alpha)
		end
	end

	return if alpha < 0.5 then a else b
end

return lerp_type
