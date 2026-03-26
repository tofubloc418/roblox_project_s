--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(context, target: Player?, state: string?)
	local t = target or context.Executor
	local devRemotes = ReplicatedStorage:FindFirstChild("DevRemotes")
	local setWeaponDebug = devRemotes and devRemotes:FindFirstChild("SetWeaponDebug") :: RemoteEvent?
	if not setWeaponDebug then
		return "SetWeaponDebug remote not found."
	end
	setWeaponDebug:FireClient(t, state or "toggle")
	return ("Weapon debug request sent to %s (%s)."):format(t.Name, state or "toggle")
end
