--!strict
local DevCommandRunner = require(script.Parent.Parent:WaitForChild("DevCommandRunner"))

return function(context, abilityId: string, weaponTag: string, slot: number, target: Player?)
	local sender = context.Executor
	local result = DevCommandRunner.runSetAbilityPreset(sender, abilityId, weaponTag, slot, target)
	for _, line in ipairs(result.lines) do
		context:Reply(line)
	end
	return ""
end
