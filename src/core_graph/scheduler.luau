type work = () -> ()

local scheduled: { work } = {}

local function flush()
	for _, work in scheduled do
		work()
	end

	table.clear(scheduled)
end

local function schedule(work: work)
	table.insert(scheduled, work)
end

return {
	flush = flush,
	schedule = schedule,
}
