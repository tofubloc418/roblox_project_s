--!strict

export type ActiveMovement = {
	Cancel: (self: ActiveMovement) -> (),
	IsActive: (self: ActiveMovement) -> boolean,
	Completed: CompletedSignal,
}

export type CompletedSignal = {
	Connect: (self: CompletedSignal, cb: (didComplete: boolean) -> ()) -> SimpleConnection,
}

export type SimpleConnection = {
	Disconnect: (self: SimpleConnection) -> (),
}

type Callback = (didComplete: boolean) -> ()

local function createSignal(): CompletedSignal & { _Fire: (self: any, didComplete: boolean) -> () }
	local listeners: { Callback } = {}
	local signal = {} :: any
	function signal:Connect(cb: Callback): SimpleConnection
		table.insert(listeners, cb)
		local alive = true
		return {
			Disconnect = function()
				if not alive then
					return
				end
				alive = false
				for i = #listeners, 1, -1 do
					if listeners[i] == cb then
						table.remove(listeners, i)
						break
					end
				end
			end,
		}
	end
	function signal:_Fire(didComplete: boolean)
		local snap = table.clone(listeners)
		table.clear(listeners)
		for _, cb in snap do
			task.defer(cb, didComplete)
		end
	end
	return signal
end

type CancelFn = () -> ()

export type ActiveMovementOptions = {
	onCancel: CancelFn?,
}

local function noop() end

local ActiveMovementModule = {}

function ActiveMovementModule.new(
	onCompleteCleanup: (token: ActiveMovement) -> (),
	options: ActiveMovementOptions?
): ActiveMovement
	local signal = createSignal()
	local active = true
	local cancelFn: CancelFn = if options and options.onCancel then options.onCancel else noop

	local token: ActiveMovement
	token = {
		Completed = signal,
		IsActive = function(_self: ActiveMovement): boolean
			return active
		end,
		Cancel = function(_self: ActiveMovement)
			if not active then
				return
			end
			active = false
			cancelFn()
			onCompleteCleanup(token)
			(signal :: any):_Fire(false)
		end,
	} :: any

	;(token :: any)._finish = function()
		if not active then
			return
		end
		active = false
		onCompleteCleanup(token)
		(signal :: any):_Fire(true)
	end

	return token
end

function ActiveMovementModule.finish(token: ActiveMovement)
	local fn = (token :: any)._finish
	if fn then
		fn()
	end
end

return ActiveMovementModule
