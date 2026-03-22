--!strict

local Maid = {}
Maid.ClassName = "Maid"
Maid.__index = Maid

local TaskTypes = {
	["function"] = function(task: () -> ())
		task()
	end,
	["Instance"] = game.Destroy,
	["RBXScriptConnection"] = function(task: RBXScriptConnection)
		task:Disconnect()
	end,
	["table"] = function(task: { Destroy: ((any) -> any)?, Disconnect: ((any) -> any)? })
		local destroy = task.Destroy
		local disconnect = task.Disconnect
		if type(destroy) == "function" then
			destroy(task)
		elseif type(disconnect) == "function" then
			disconnect(task)
		end
	end,
	["thread"] = function(threadRef: thread)
		local cancelled
		if coroutine.running() ~= threadRef then
			cancelled = pcall(function()
				task.cancel(threadRef)
			end)
		end

		if not cancelled then
			local toCancel = threadRef
			task.defer(function()
				task.cancel(toCancel)
			end)
		end
	end,
}

function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

function Maid:GiveTask(givenTask: any): any
	table.insert(self._tasks, givenTask)
	return givenTask
end

function Maid:BindToInstance(object: Instance, beforeCleaning: (() -> ())?): () -> ()
	assert(typeof(object) == "Instance", "[Maid]: Attempted to BindToInstance a non instance object.")
	local destroyedConnection = self:GiveTask(object.Destroying:Once(function()
		if beforeCleaning then
			beforeCleaning()
		end

		self:DoCleaning()
	end))

	return function()
		destroyedConnection:Disconnect()
	end
end

function Maid:BindToHumanoid(object: Humanoid, beforeCleaning: (() -> ())?): () -> ()
	assert(object:IsA("Humanoid"), "[Maid]: Attempted to BindToHumanoid a non humanoid object.")
	local destroyed = self:BindToInstance(object)
	local diedConnection = self:GiveTask(object.Died:Once(function()
		if beforeCleaning then
			beforeCleaning()
		end

		self:DoCleaning()
	end))

	return function()
		destroyed()
		diedConnection:Disconnect()
	end
end

function Maid:DoCleaning()
	for _, task in ipairs(self._tasks) do
		local taskType = TaskTypes[typeof(task)]
		if taskType then
			local success, response = pcall(function()
				taskType(task)
			end)

			if not success and response then
				warn(response)
			end
		end
	end

	table.clear(self._tasks)
end

Maid.Destroy = Maid.DoCleaning

return Maid
