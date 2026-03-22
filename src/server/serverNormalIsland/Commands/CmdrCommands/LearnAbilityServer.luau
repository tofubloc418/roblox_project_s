--!strict
local DevCommandRunner = require(script.Parent.Parent:WaitForChild("DevCommandRunner"))

return function(context, abilityId: string, target: Player?)
	local sender = context.Executor
	local result = DevCommandRunner.runLearnAbility(sender, abilityId, target)
	for _, line in ipairs(result.lines) do
		context:Reply(line)
	end
	return ""
end
