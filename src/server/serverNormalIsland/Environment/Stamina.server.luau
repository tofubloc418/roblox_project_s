local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

-- Input remotes for reliable client -> server intent
local inputRemotes = ReplicatedStorage:FindFirstChild("InputRemotes")
if not inputRemotes then
    inputRemotes = Instance.new("Folder")
    inputRemotes.Name = "InputRemotes"
    inputRemotes.Parent = ReplicatedStorage
end
local setSprintRemote = inputRemotes:FindFirstChild("SetSprint")
if not setSprintRemote then
    setSprintRemote = Instance.new("RemoteEvent")
    setSprintRemote.Name = "SetSprint"
    setSprintRemote.Parent = inputRemotes
end
local jumpPressedRemote = inputRemotes:FindFirstChild("JumpPressed")
if not jumpPressedRemote then
    jumpPressedRemote = Instance.new("RemoteEvent")
    jumpPressedRemote.Name = "JumpPressed"
    jumpPressedRemote.Parent = inputRemotes
end

local lastJumpCharge: {[Player]: number} = {}

local function stepPlayer(player: Player, dt: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local maxStamina = player:GetAttribute("MaxStamina") or (PlayerConfig.baseMaxStamina or 100)
	local stamina = player:GetAttribute("Stamina") or maxStamina
	local wantsSprint = player:GetAttribute("WantsSprint") == true

	-- Determine state
	local movingMode = "walk"
	if humanoid then
		if wantsSprint and stamina > 0 then
			movingMode = "run"
			humanoid.WalkSpeed = PlayerConfig.runSpeed or 20
		else
			humanoid.WalkSpeed = PlayerConfig.walkSpeed or 14
		end
		if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			movingMode = "swim"
		end
	end

	-- Drain/regen
	local drain = 0
	if movingMode == "run" then
		drain = (PlayerConfig.staminaRunDrainPerSecond or 15) * dt
	elseif movingMode == "swim" then
		-- Only drain when actually moving in water
		local vel = character and character.PrimaryPart and character.PrimaryPart.AssemblyLinearVelocity or Vector3.zero
		local horizontal = Vector3.new(vel.X, 0, vel.Z).Magnitude
		if horizontal > 1 then
			drain = (PlayerConfig.staminaSwimDrainPerSecond or 15) * dt
		end
	else
		-- walking: regen
		stamina = math.min(maxStamina, stamina + (PlayerConfig.staminaRegenPerSecond or 12) * dt)
	end
	stamina = math.max(0, stamina - drain)

	-- Apply
	player:SetAttribute("Stamina", stamina)

	-- Enforce jump gating based on stamina threshold (cost)
	if humanoid then
		local cost = PlayerConfig.jumpStaminaCost or 20
		local allow = stamina >= cost
		-- Toggle Jumping state and power
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, allow)
		humanoid.JumpPower = allow and (PlayerConfig.jumpPower or 50) or 0
		if not allow and humanoid.Jump == true then
			humanoid.Jump = false
		end
	end

	-- Health penalty if swimming with zero stamina while moving
	if movingMode == "swim" and stamina <= 0 and humanoid and character and character.PrimaryPart then
		local vel = character.PrimaryPart.AssemblyLinearVelocity
		local horizontal = Vector3.new(vel.X, 0, vel.Z).Magnitude
		if horizontal > 1 then
			humanoid:TakeDamage((PlayerConfig.staminaSwimHealthDrainPerSecond or 5) * dt)
		end
	end
end

-- Jump cost: hook Humanoid.Jumping per character
local function onCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.Jumping:Connect(function(active)
		if active then
			local maxStamina = player:GetAttribute("MaxStamina") or (PlayerConfig.baseMaxStamina or 100)
			local stamina = player:GetAttribute("Stamina") or maxStamina
			local cost = PlayerConfig.jumpStaminaCost or 20
			if stamina >= cost then
				player:SetAttribute("Stamina", stamina - cost)
			else
				-- Prevent jump by lowering JumpPower briefly
				local jp = humanoid.JumpPower
				humanoid.JumpPower = 0
				task.delay(0.15, function()
					humanoid.JumpPower = jp
				end)
			end
		end
	end)
end

-- Heartbeat loop
game:GetService("RunService").Heartbeat:Connect(function(dt)
	for _, plr in ipairs(Players:GetPlayers()) do
		stepPlayer(plr, math.clamp(dt, 0, 0.5))
	end
end)

-- Character hookup
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		onCharacter(plr, char)
	end)
end)


-- Remote handlers for reliable input intent
setSprintRemote.OnServerEvent:Connect(function(player: Player, desired: boolean)
	player:SetAttribute("WantsSprint", desired == true)
end)

jumpPressedRemote.OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	local last = lastJumpCharge[player] or 0
	if (now - last) < 0.2 then
		return
	end
	lastJumpCharge[player] = now

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local maxStamina = player:GetAttribute("MaxStamina") or (PlayerConfig.baseMaxStamina or 100)
	local stamina = player:GetAttribute("Stamina") or maxStamina
	local cost = PlayerConfig.jumpStaminaCost or 20

	if stamina >= cost then
		player:SetAttribute("Stamina", stamina - cost)
	else
		if humanoid then
			local jp = humanoid.JumpPower
			humanoid.JumpPower = 0
			task.delay(0.15, function()
				humanoid.JumpPower = jp
			end)
		end
	end
end)


