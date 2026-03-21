local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local external = require("../core_external/types")

local ExternalScheduler = require("../core_external/ExternalScheduler")

local scheduler_disconnect: () -> ()? = nil

local RobloxScheduler: external.ExternalScheduler = {
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
				ExternalScheduler.perform_update_step
			)

			scheduler_disconnect = function()
				RunService:UnbindFromRenderStep(id)
			end
		else
			local connection = RunService.Heartbeat:Connect(ExternalScheduler.perform_update_step)

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
}

return table.freeze(RobloxScheduler)
