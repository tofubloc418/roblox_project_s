--!strict
-- Ability client dispatcher: AbilityStarted is fired to every client with (casterUserId, abilityId, slotIndex).
-- Each client runs OnStarted using the caster’s replicated Character so local VFX is visible to everyone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local keybindsFolder = ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Keybinds")
local KeybindIds = require(keybindsFolder:WaitForChild("KeybindIds"))
local KeybindsClient = require(script.Parent.Parent:WaitForChild("Input"):WaitForChild("KeybindsClient"))
local HudLoadoutDataAdapter = require(script.Parent.Parent:WaitForChild("GUI"):WaitForChild("HudLoadout"):WaitForChild("HudLoadoutDataAdapter"))

export type AbilityClientContext = {
	player: Player,
	character: Model,
	abilityId: string,
	slotIndex: number,
	animator: Animator?,
}

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local requestUseAbility = remotes:WaitForChild("RequestUseAbility") :: RemoteEvent
local abilityStarted = remotes:WaitForChild("AbilityStarted") :: RemoteEvent

local scriptsFolder = script.Parent:WaitForChild("Scripts", 5)

if scriptsFolder then
	abilityStarted.OnClientEvent:Connect(function(casterUserId: unknown, abilityId: unknown, slotIndex: unknown)
		if type(casterUserId) ~= "number" or type(abilityId) ~= "string" or type(slotIndex) ~= "number" then
			return
		end
		local uid = casterUserId :: number
		local aid = abilityId :: string
		local slotN = slotIndex :: number

		local caster = Players:GetPlayerByUserId(uid)
		if not caster then
			return
		end
		local character = caster.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator: Animator? = humanoid and humanoid:FindFirstChildOfClass("Animator") or nil

		local abilityModule = scriptsFolder:FindFirstChild(aid)
		if not abilityModule or not abilityModule:IsA("ModuleScript") then
			return
		end

		local ok, abilityScript = pcall(require, abilityModule :: ModuleScript)
		if not ok or type(abilityScript) ~= "table" then
			return
		end

		local onStarted = abilityScript.OnStarted
		if type(onStarted) == "function" then
			local context: AbilityClientContext = {
				player = caster,
				character = character,
				abilityId = aid,
				slotIndex = slotN,
				animator = animator,
			}
			onStarted(context)
		end
	end)
end

local SLOT_ACTIONS: { string } = {
	KeybindIds.AbilitySlot1,
	KeybindIds.AbilitySlot2,
	KeybindIds.AbilitySlot3,
	KeybindIds.AbilitySlot4,
	KeybindIds.AbilitySlot5,
}

for slotIndex, actionId in ipairs(SLOT_ACTIONS) do
	KeybindsClient.bindAction(
		actionId,
		function(_name: string, state: Enum.UserInputState, _input: InputObject)
			-- Keybinds UI capture uses the same keys; avoid firing abilities while rebinding.
			if KeybindsClient.areGameplayActionsSuppressed() then
				return Enum.ContextActionResult.Sink
			end
			if state == Enum.UserInputState.Begin then
				local barKey = HudLoadoutDataAdapter.getAbilityBarPresetKey()
				requestUseAbility:FireServer(slotIndex, barKey)
			end
			return Enum.ContextActionResult.Sink
		end,
		{
			actionName = "AbilitySlot" .. tostring(slotIndex),
		}
	)
end
