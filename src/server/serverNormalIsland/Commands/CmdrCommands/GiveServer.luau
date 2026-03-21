--!strict
local DevCommandRunner = require(script.Parent.Parent:WaitForChild("DevCommandRunner"))

return function(context, templateId: string, target: Player?, count: number?)
	local sender = context.Executor
	local args: { string }
	if target then
		args = { target.Name, templateId, tostring(count or 1) }
	else
		args = { templateId, tostring(count or 1) }
	end
	local result = DevCommandRunner.runGive(sender, args)
	for _, line in ipairs(result.lines) do
		context:Reply(line)
	end
	return ""
end
