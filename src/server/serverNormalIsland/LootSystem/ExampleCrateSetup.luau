--[[
	ExampleCrateSetup
	Example script showing how to manually set up crates in Studio
	
	Instructions:
	1. Create a Model in workspace
	2. Add a Part as a child (this will be the crate body)
	3. Set the Model's PrimaryPart to that Part
	4. Add these attributes to the Model:
	   - CrateType (string): "Normal", "NormalPlus", "WeaponCrate", "GrenadeBox", "MedicalCrate", "Elite", etc.
	   - MaxHealth (number): Optional, defaults to value in LootConfig
	5. The system will automatically register the crate when the game runs
	
	For visual stages, add child Models or Parts named:
	   - Stage0 (normal appearance)
	   - Stage1_Cracked (light damage)
	   - Stage2_Heavy (heavy damage)
]]

-- This is not an executable script, just documentation
-- Below is example code showing how to create a crate programmatically:

local function createExampleCrate()
	-- Create the crate model
	local crateModel = Instance.new("Model")
	crateModel.Name = "Crate_Example"
	
	-- Create the main body
	local body = Instance.new("Part")
	body.Name = "CrateBody"
	body.Size = Vector3.new(4, 4, 4)
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Color = Color3.fromRGB(139, 69, 19) -- Brown
	body.Material = Enum.Material.Wood
	body.Parent = crateModel
	
	-- Set as primary part
	crateModel.PrimaryPart = body
	
	-- Create visual stages (optional)
	-- Stage 0 - Normal
	local stage0 = body:Clone()
	stage0.Name = "Stage0"
	stage0.Transparency = 0
	stage0.Parent = crateModel
	
	-- Stage 1 - Light crack
	local stage1 = body:Clone()
	stage1.Name = "Stage1_Cracked"
	stage1.Transparency = 1 -- Hidden by default
	stage1.Color = Color3.fromRGB(100, 50, 10) -- Darker brown
	
	-- Add crack decal (example)
	local crackDecal = Instance.new("Decal")
	crackDecal.Texture = "rbxasset://textures/cracks.png" -- Placeholder
	crackDecal.Transparency = 0.5
	crackDecal.Face = Enum.NormalId.Front
	crackDecal.Parent = stage1
	
	stage1.Parent = crateModel
	
	-- Stage 2 - Heavy crack
	local stage2 = body:Clone()
	stage2.Name = "Stage2_Heavy"
	stage2.Transparency = 1 -- Hidden by default
	stage2.Color = Color3.fromRGB(60, 30, 5) -- Very dark brown
	
	-- Add more crack decals
	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		if face ~= Enum.NormalId.Bottom then
			local decal = Instance.new("Decal")
			decal.Texture = "rbxasset://textures/cracks.png" -- Placeholder
			decal.Transparency = 0.3
			decal.Face = face
			decal.Parent = stage2
		end
	end
	
	stage2.Parent = crateModel
	
	-- Set attributes
	crateModel:SetAttribute("CrateType", "Normal")
	crateModel:SetAttribute("MaxHealth", 100)
	
	-- Position the crate
	crateModel:PivotTo(CFrame.new(0, 5, 0))
	
	-- Parent to workspace
	crateModel.Parent = workspace
	
	return crateModel
end

-- Available crate types from LootConfig:
local CRATE_TYPES = {
	"Normal",        -- Standard loot
	"NormalPlus",    -- Better loot
	"WeaponCrate",   -- Weapons and ammo
	"GrenadeBox",    -- Grenades only
	"MedicalCrate",  -- Medical supplies
	"Elite",         -- High tier loot
	"MosinOnly",     -- Specific weapon
}

-- Example attributes for different crate types:
local CRATE_EXAMPLES = {
	{
		Name = "StandardLootCrate",
		CrateType = "Normal",
		MaxHealth = 100,
	},
	{
		Name = "EliteLootCrate", 
		CrateType = "Elite",
		MaxHealth = 200,
	},
	{
		Name = "WeaponBox",
		CrateType = "WeaponCrate",
		MaxHealth = 120,
	},
	{
		Name = "MedicalSupplies",
		CrateType = "MedicalCrate",
		MaxHealth = 80,
	},
}

return {
	CreateExampleCrate = createExampleCrate,
	CrateTypes = CRATE_TYPES,
	Examples = CRATE_EXAMPLES,
}
