--!strict
--!native
--!optimize 2

const springs = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_warn = ExternalLogger.log_warn

const Oklab = require("../colour/Oklab")
const oklab_to_srgb = Oklab.oklab_to_srgb

const Roblox = require("../colour/Roblox")
const vector_to_Color3 = Roblox.vector_to_Color3

const function pack_type(data_type: string, array: { number }): unknown
	if data_type == "number" then
		return array[1]
	elseif data_type == "vector" then
		return vector.create(array[1], array[2], array[3])
	elseif data_type == "CFrame" then
		return CFrame.new(array[1], array[2], array[3])
			* CFrame.fromAxisAngle(Vector3.new(array[4], array[5], array[6]), array[7])
	elseif data_type == "Color3" then
		return vector_to_Color3(oklab_to_srgb(vector.create(array[1], array[2], array[3])))
	elseif data_type == "ColorSequenceKeypoint" then
		return ColorSequenceKeypoint.new(
			array[1],
			vector_to_Color3(oklab_to_srgb(vector.create(array[2], array[3], array[4])))
		)
	elseif data_type == "NumberRange" then
		return NumberRange.new(array[1], array[2])
	elseif data_type == "NumberSequenceKeypoint" then
		return NumberSequenceKeypoint.new(array[1], array[2], array[3])
	elseif data_type == "Rect" then
		return Rect.new(array[1], array[2], array[3], array[4])
	elseif data_type == "UDim" then
		return UDim.new(array[1], math.round(array[2]))
	elseif data_type == "UDim2" then
		return UDim2.new(array[1], math.round(array[2]), array[3], math.round(array[4]))
	elseif data_type == "Vector2" then
		return Vector3.new(array[1], array[2])
	elseif data_type == "Vector3" then
		return Vector3.new(array[1], array[2], array[3])
	end

	log_warn(springs.unknown_packing_datatype, { type = data_type })

	return nil
end

return pack_type
