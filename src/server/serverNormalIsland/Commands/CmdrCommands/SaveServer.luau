--!strict
local DevCommandRunner = require(script.Parent.Parent:WaitForChild("DevCommandRunner"))

return function(context, target: Player?)
	local sender = context.Executor
	local args: { string } = if target then { target.Name } else {}
	local result = DevCommandRunner.runSave(sender, args)
	for _, line in ipairs(result.lines) do
		context:Reply(line)
	end
	return result.lines[#result.lines] or "Done."
end
