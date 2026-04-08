type QueuedTask = {
	thread: thread,
	args: { [number]: any, n: number },
	startby: number?,
}

local QUEUE: { QueuedTask } = {}
local ACTIVE: { thread } = {}

local function tothread(f: thread | (...unknown) -> ...unknown)
	return if typeof(f) == "thread" then f else coroutine.create(f)
end

local function start_task(thread: thread, ...)
	local ok = coroutine.resume(thread, ...)

	if not ok then
		error("STARTING TASK ERRORED")
	end

	if coroutine.status(thread) == "dead" then
		return
	end

	table.insert(ACTIVE, thread)
end

return table.freeze({
	spawn = function<A...>(resume: (A...) -> () | thread, ...: A...)
		local thread = tothread(resume)

		start_task(thread, ...)

		return thread
	end,
	defer = function<A...>(resume: (A...) -> () | thread, ...: A...)
		local thread = tothread(resume)

		table.insert(QUEUE, { thread = thread, args = table.pack(...) })

		return thread
	end,
	delay = function<A...>(sec: number, resume: (A...) -> () | thread, ...: A...)
		local thread = tothread(resume)

		table.insert(QUEUE, {
			thread = thread,
			args = table.pack(...),
			startby = os.clock() + sec,
		})

		return thread
	end,

	process = function()
		local now = os.clock()

		for index = #QUEUE, 1, -1 do
			local queued_task = QUEUE[index]

			if queued_task.startby ~= nil and now < queued_task.startby then
				continue
			end

			start_task(queued_task.thread, table.unpack(queued_task.args))
		end

		for index = #ACTIVE, 1, -1 do
			local thread = ACTIVE[index]
			local ok, result: string = coroutine.resume(thread)

			if not ok then
				print("Error in scheduler: " .. result)
			end

			if coroutine.status(thread) == "dead" then
				table.remove(ACTIVE, index)
			end
		end
	end,
})
