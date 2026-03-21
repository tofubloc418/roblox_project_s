--!strict
local Players = game:GetService("Players")

return function(context)
	local list = Players:GetPlayers()
	context:Reply(("[Dev] %d player(s) in server:"):format(#list))
	for i, p in ipairs(list) do
		context:Reply(("  %d) %s (UserId=%d)"):format(i, p.Name, p.UserId))
	end
	return ""
end
