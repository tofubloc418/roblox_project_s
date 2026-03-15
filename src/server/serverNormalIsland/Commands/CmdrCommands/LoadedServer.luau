--!strict
local Players = game:GetService("Players")

return function(context)
	local list = Players:GetPlayers()
	context:Reply(("[Dev] Data load status (%d player(s)):"):format(#list))
	for _, p in ipairs(list) do
		if p:GetAttribute("_DataLoaded") then
			context:Reply(("  [OK]      %s"):format(p.Name))
		else
			context:Reply(("  [NO DATA] %s"):format(p.Name))
		end
	end
	return "Done."
end
