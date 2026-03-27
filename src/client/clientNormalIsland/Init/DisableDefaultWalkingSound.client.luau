--!strict

-- Mutes Roblox's stock footstep loop (CharacterSounds.Running).

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local connections: { RBXScriptConnection } = {}

local function disconnectAll()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function muteIfRunning(sound: Instance)
	if sound.Name == "Running" and sound:IsA("Sound") then
		sound.Volume = 0
	end
end

local function bindSoundsFolder(folder: Instance)
	for _, child in folder:GetChildren() do
		muteIfRunning(child)
	end
	table.insert(connections, folder.ChildAdded:Connect(muteIfRunning))
end

local function bindCharacter(character: Model)
	disconnectAll()

	local existing = character:FindFirstChild("CharacterSounds")
	if existing then
		bindSoundsFolder(existing)
	else
		table.insert(connections, character.ChildAdded:Connect(function(child)
			if child.Name == "CharacterSounds" then
				bindSoundsFolder(child)
			end
		end))
	end
end

if localPlayer.Character then
	task.spawn(bindCharacter, localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(bindCharacter)
