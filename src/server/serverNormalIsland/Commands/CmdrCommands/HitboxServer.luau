--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(context, target: Player?, state: string?)
	local t = target or context.Executor
	local devRemotes = ReplicatedStorage:FindFirstChild("DevRemotes")
	local setHitboxDebug = devRemotes and devRemotes:FindFirstChild("SetHitboxDebug") :: RemoteEvent?
	if not setHitboxDebug then
		return "SetHitboxDebug remote not found."
	end
	setHitboxDebug:FireClient(t, state or "toggle")
	return ("Hitbox debug request sent to %s (%s)."):format(t.Name, state or "toggle")
end
