--!strict

local weakFreeRunnerThreadLookup: any = setmetatable({}, { __mode = "kv" })

local function acquireRunnerThreadAndCallEventHandler(memoryCategory: string, fn: any, ...: any)
	local acquiredRunnerThread = weakFreeRunnerThreadLookup[memoryCategory]
	weakFreeRunnerThreadLookup[memoryCategory] = nil
	fn(...)
	weakFreeRunnerThreadLookup[memoryCategory] = acquiredRunnerThread
end

local function runEventHandlerInFreeThread(memoryCategory: string)
	local dbg = debug :: any
	if #memoryCategory == 0 then
		dbg.setmemorycategory("signal_unknown")
	else
		dbg.setmemorycategory(memoryCategory)
	end

	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.ClassName = "Connection"
Connection.__index = Connection

function Connection.new(signal: any, fn: (...any) -> ())
	return setmetatable({
		_memoryCategory = (debug :: any).getmemorycategory() :: string,
		_signal = signal,
		_fn = fn,
	}, Connection)
end

function Connection:IsConnected()
	return rawget(self :: any, "_signal") ~= nil
end

function Connection:Disconnect()
	local signal = rawget(self :: any, "_signal")
	if not signal then
		return
	end

	local ourNext = rawget(self :: any, "_next")

	if signal._handlerListHead == self then
		signal._handlerListHead = ourNext or false
	else
		local prev = signal._handlerListHead
		while prev and rawget(prev :: any, "_next") ~= self do
			prev = rawget(prev :: any, "_next")
		end
		if prev then
			rawset(prev :: any, "_next", ourNext)
		end
	end

	table.clear(self)
end

Connection.Destroy = Connection.Disconnect

local Signal = {}
Signal.ClassName = "Signal"
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_handlerListHead = false,
	}, Signal)
end

function Signal.isSignal(value)
	return type(value) == "table" and getmetatable(value) == Signal
end

function Signal:Connect(fn: (...any) -> ())
	local connection = Connection.new(self, fn)
	if self._handlerListHead then
		rawset(connection :: any, "_next", self._handlerListHead)
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end
	return connection
end

function Signal:DisconnectAll()
	self._handlerListHead = false
end

function Signal:Fire(...)
	local connection: any = self._handlerListHead
	while connection do
		local nextNode = rawget(connection, "_next")

		if rawget(connection, "_signal") ~= nil then
			local memoryCategory = connection._memoryCategory

			if not weakFreeRunnerThreadLookup[memoryCategory] then
				weakFreeRunnerThreadLookup[memoryCategory] = coroutine.create(runEventHandlerInFreeThread)
				coroutine.resume(weakFreeRunnerThreadLookup[memoryCategory], memoryCategory)
			end

			task.spawn(weakFreeRunnerThreadLookup[memoryCategory], memoryCategory, connection._fn, ...)
		end

		connection = nextNode
	end
end

function Signal:Wait()
	local waitingCoroutine = coroutine.running()
	assert(waitingCoroutine, "Signal:Wait must be called from a thread")

	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)

	return coroutine.yield()
end

function Signal:Once(fn: (...any) -> ())
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)
	return connection
end

Signal.Destroy = Signal.DisconnectAll

return Signal
