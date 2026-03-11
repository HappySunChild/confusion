local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local external = require("../core_external/types")

local External = require("../core_external/External")

local scheduler_disconnect

local RobloxProvider = table.freeze({
	do_task_immediate = task.spawn,
	do_task_deferred = task.defer,
	do_task_delayed = task.delay,
	cancel_task = function(thread: thread)
		local success = pcall(task.cancel, thread)

		return success
	end,

	start_scheduler = function()
		if RunService:IsClient() then
			local id = "FusionUpdateStep_" .. HttpService:GenerateGUID(false)

			RunService:BindToRenderStep(
				id,
				Enum.RenderPriority.First.Value,
				External.perform_update_step
			)

			scheduler_disconnect = function()
				RunService:UnbindFromRenderStep(id)
			end
		else
			local connection = RunService.Heartbeat:Connect(External.perform_update_step)

			scheduler_disconnect = function()
				connection:Disconnect()
			end
		end
	end,
	stop_scheduler = function()
		if scheduler_disconnect ~= nil then
			scheduler_disconnect()
			scheduler_disconnect = nil
		end
	end,
})

return RobloxProvider :: external.ExternalProvider
