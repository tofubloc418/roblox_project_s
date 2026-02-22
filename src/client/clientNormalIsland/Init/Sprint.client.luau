local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local inputRemotes = ReplicatedStorage:WaitForChild("InputRemotes")
local setSprintRemote: RemoteEvent = inputRemotes:WaitForChild("SetSprint")
local jumpPressedRemote: RemoteEvent = inputRemotes:WaitForChild("JumpPressed")

local player = Players.LocalPlayer

-- Toggle sprint desire and adjust walkspeed locally for responsiveness
local function setSprint(desired: boolean)
	player:SetAttribute("WantsSprint", desired)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))
	if humanoid and PlayerConfig then
		local stamina = player:GetAttribute("Stamina") or (PlayerConfig.baseMaxStamina or 100)
		local canRun = stamina > 0
		local want = desired and canRun
		humanoid.WalkSpeed = want and (PlayerConfig.runSpeed or 20) or (PlayerConfig.walkSpeed or 14)
	end
    setSprintRemote:FireServer(desired)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		setSprint(true)
	elseif input.KeyCode == Enum.KeyCode.Space then
		-- Explicit jump press logger for debugging
		print("[Input] Space pressed for jump")
		jumpPressedRemote:FireServer()
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end
	if not input.KeyCode or input.KeyCode == Enum.KeyCode.Unknown then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		setSprint(false)
	elseif input.KeyCode == Enum.KeyCode.Space then
		print("[Input] Space released")
	end
end)

-- Observe stamina to auto-drop sprint when depleted
player:GetAttributeChangedSignal("Stamina"):Connect(function()
	local stamina = player:GetAttribute("Stamina") or 0
	if stamina <= 0 then
		setSprint(false)
	end
	-- Client jump gating for immediate UX: mirror server
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))
		local cost = PlayerConfig.jumpStaminaCost or 20
		local allow = stamina >= cost
		humanoid.JumpPower = allow and (PlayerConfig.jumpPower or 50) or 0
	end
end)

-- Sink Space when jumping is disallowed to prevent attempt
local CAS = game:GetService("ContextActionService")
local function blockJump(_, state, input)
    if state == Enum.UserInputState.Begin then
        local stamina = player:GetAttribute("Stamina") or 0
        local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))
        local cost = PlayerConfig.jumpStaminaCost or 20
        if stamina < cost then
            print("[Input] Jump blocked (client) due to low stamina")
            return Enum.ContextActionResult.Sink
        end
    end
    return Enum.ContextActionResult.Pass
end
CAS:BindAction("BlockJumpOnLowStamina", blockJump, false, Enum.KeyCode.Space)


