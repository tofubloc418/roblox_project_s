-- This server script goes inside each gun tool
-- It simply ensures the gun has required components

local tool = script.Parent

-- Create shoot event if it doesn't exist
if not tool:FindFirstChild("shoot") then
	local shootEvent = Instance.new("RemoteEvent")
	shootEvent.Name = "shoot"
	shootEvent.Parent = tool
end

-- Ensure sounds folder exists
if not tool:FindFirstChild("Sounds") then
	local soundsFolder = Instance.new("Folder")
	soundsFolder.Name = "Sounds"
	soundsFolder.Parent = tool
	
	-- You'll need to add the actual sound objects with proper IDs
	local equipSound = Instance.new("Sound")
	equipSound.Name = "Gun Equip"
	equipSound.Volume = 0.5
	equipSound.Parent = soundsFolder
	
	local reloadSound = Instance.new("Sound")
	reloadSound.Name = "Gun Reload"
	reloadSound.Volume = 0.5
	reloadSound.Parent = soundsFolder
	
	local shotSound = Instance.new("Sound")
	shotSound.Name = "Gun Shot"
	shotSound.Volume = 0.5
	shotSound.Parent = soundsFolder
end
