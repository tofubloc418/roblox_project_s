--!strict
local Players = game:GetService("Players")

return function(context, target: Player?)
	local p = target or context.Executor
	context:Reply(("[Dev] Stats for '%s':"):format(p.Name))
	local attributes = p:GetAttributes()
	local attrCount = 0
	for _ in pairs(attributes) do
		attrCount += 1
	end
	context:Reply(("  --- Attributes (%d) ---"):format(attrCount))
	for k, v in pairs(attributes) do
		context:Reply(("    [%s] = %s"):format(tostring(k), tostring(v)))
	end
	local leaderstats = p:FindFirstChild("leaderstats")
	if leaderstats then
		local children = leaderstats:GetChildren()
		context:Reply(("  --- leaderstats (%d) ---"):format(#children))
		for _, stat in ipairs(children) do
			if stat:IsA("ValueBase") then
				context:Reply(("    [%s] = %s"):format(stat.Name, tostring((stat :: any).Value)))
			end
		end
	else
		context:Reply("  --- No leaderstats found ---")
	end
	return "Done."
end
