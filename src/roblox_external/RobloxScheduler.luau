const HttpService = game:GetService("HttpService")
const RunService = game:GetService("RunService")

const external = require("../core_external/types")

const ExternalScheduler = require("../core_external/ExternalScheduler")

local scheduler_disconnect: () -> ()? = nil

const RobloxScheduler: external.ExternalScheduler = {
	schedule_task_immediate = task.spawn,
	schedule_task_deferred = task.defer,
	schedule_task_delayed = task.delay,
	cancel_task = function(thread: thread)
		const success = pcall(task.cancel, thread)

		return success
	end,

	start_scheduler = function()
		if RunService:IsClient() then
			const id = "FusionUpdateStep_" .. HttpService:GenerateGUID(false)

			RunService:BindToRenderStep(id, Enum.RenderPriority.First.Value, ExternalScheduler.perform_update_step)

			scheduler_disconnect = function()
				RunService:UnbindFromRenderStep(id)
			end
		else
			const connection = RunService.Heartbeat:Connect(ExternalScheduler.perform_update_step)

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
