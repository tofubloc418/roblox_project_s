--!strict
local DevCommandRunner = require(script.Parent.Parent:WaitForChild("DevCommandRunner"))

return function(context, filter: string?)
	local args: { string } = if filter and filter ~= "" then { filter } else {}
	local result = DevCommandRunner.runItems(context.Executor, args)
	for _, line in ipairs(result.lines) do
		context:Reply(line)
	end
	return result.lines[#result.lines] or "Done."
end
