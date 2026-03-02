--[[
	Initializer
	Server script that initializes and wires together game systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Shared modules
local RoundState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RoundState"))
local PlayerConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("PlayerConfig"))

-- Combat modules
local CombatModules = script.Parent:WaitForChild("Combat")
local DamageService = require(CombatModules:WaitForChild("DamageService"))

-- Weapon modules
local WeaponModules = script.Parent:WaitForChild("Weapons")
local MeleeService = require(WeaponModules:WaitForChild("MeleeService"))

-- Med modules
local MedModules = script.Parent:WaitForChild("Med")
local MedService = require(MedModules:WaitForChild("MedService"))

-- Stats module
local StatsModules = script.Parent:WaitForChild("Stats")
local StatsService = require(StatsModules:WaitForChild("StatsService"))

print("[Initializer] Starting...")

local StarterPlayer = game:GetService("StarterPlayer")

StarterPlayer:SetAttribute("ForceR15", true)
StarterPlayer:SetAttribute("IgnoreCharacterAppearance", true)

-- Initialize RoundState with a seed
local roundState = RoundState.Current()
roundState:Initialize()

-- Create InventoryRemotes (placeholder until new InventoryService is implemented)
-- Client LoadoutController and HudLoadout depend on these existing
local inventoryRemotes = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if not inventoryRemotes then
	inventoryRemotes = Instance.new("Folder")
	inventoryRemotes.Name = "InventoryRemotes"
	inventoryRemotes.Parent = ReplicatedStorage

	local updateInventory = Instance.new("RemoteEvent")
	updateInventory.Name = "UpdateInventory"
	updateInventory.Parent = inventoryRemotes

	local requestEquip = Instance.new("RemoteEvent")
	requestEquip.Name = "RequestEquip"
	requestEquip.Parent = inventoryRemotes

	local requestSwap = Instance.new("RemoteEvent")
	requestSwap.Name = "RequestSwap"
	requestSwap.Parent = inventoryRemotes

	local requestDrop = Instance.new("RemoteEvent")
	requestDrop.Name = "RequestDrop"
	requestDrop.Parent = inventoryRemotes

	-- No server handlers: inventory system is deprecated. Client UI will not receive updates.
end

-- Expose universal match start time
local matchInfoFolder = ReplicatedStorage:FindFirstChild("MatchInfo")
if not matchInfoFolder then
    matchInfoFolder = Instance.new("Folder")
    matchInfoFolder.Name = "MatchInfo"
    matchInfoFolder.Parent = ReplicatedStorage
end
local startTime = matchInfoFolder:FindFirstChild("StartTime")
if not startTime then
    startTime = Instance.new("NumberValue")
    startTime.Name = "StartTime"
    startTime.Value = os.time()
    startTime.Parent = matchInfoFolder
end

-- Initialize services
StatsService:Initialize()
MeleeService:Initialize()
MedService:Initialize()

-- Enforce humanoid rig type and scale on character spawn
local function applyCharacterConfig(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	local maxHealth = player and player:GetAttribute("MaxHP") or PlayerConfig.maxHealth
	local walkSpeed = player and player:GetAttribute("WalkSpeed") or PlayerConfig.walkSpeed

	if PlayerConfig.humanoidRigType == "R15" then
		humanoid.RigType = Enum.HumanoidRigType.R15

		-- Force blocky R15 (no Rthro): reset body part IDs and proportions to default
		task.defer(function()
			local ok, dc = pcall(function()
				return humanoid:GetAppliedDescription()
			end)
			if ok and dc then
				dc.Head = 0
				dc.Torso = 0
				dc.LeftArm = 0
				dc.RightArm = 0
				dc.LeftLeg = 0
				dc.RightLeg = 0
				dc.HeadScale = 1
				dc.HeightScale = 1
				dc.WidthScale = 1
				dc.BodyTypeScale = 1
				dc.DepthScale = 1
				dc.ProportionScale = 1
				pcall(function()
					humanoid:ApplyDescription(dc)
				end)
				-- Re-apply PlayerConfig scale after blocky reset
				local scale = PlayerConfig.scale
				if scale then
					local function setScale(name: string, value: number)
						local s = humanoid:FindFirstChild(name)
						if not s then
							s = Instance.new("NumberValue")
							s.Name = name
							s.Parent = humanoid
						end
						s.Value = value
					end
					setScale("BodyHeightScale", scale.height)
					setScale("BodyWidthScale", scale.width)
					setScale("BodyDepthScale", scale.depth)
					setScale("HeadScale", scale.head)
				end
			end
		end)
	else
		humanoid.RigType = Enum.HumanoidRigType.R6
	end

	-- Basic movement/health (from stats system when available)
	humanoid.WalkSpeed = walkSpeed
	humanoid.JumpPower = PlayerConfig.jumpPower
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
end

Players.PlayerAdded:Connect(function(player)
	-- StatsService replicates MaxStamina (from MaxEnergy) on container creation
	if player:GetAttribute("MaxStamina") == nil then
		player:SetAttribute("MaxStamina", PlayerConfig.baseMaxStamina or 100)
	end
	if player:GetAttribute("Stamina") == nil then
		player:SetAttribute("Stamina", player:GetAttribute("MaxStamina") or PlayerConfig.baseMaxStamina or 100)
	end
	player:SetAttribute("WantsSprint", false)
	player.CharacterAdded:Connect(function(character)
		applyCharacterConfig(character)
	end)
end)

print("[Initializer] Initialization complete")

-- Export refs for convenience (optional)
_G.Services = {
	StatsService = StatsService,
	DamageService = DamageService,
}
