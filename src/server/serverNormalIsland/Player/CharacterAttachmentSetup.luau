--!strict
--[[
	Declarative Attachment instances on player characters (server-side).
	Edit CHARACTER_ATTACHMENTS below; Initializer runs Apply() after the rig is ready.

	- partName: direct child name of the character Model (e.g. HumanoidRootPart, LeftFoot).
	- position: Attachment.Position in that part's local space (studs).
	- axis / secondaryAxis: optional; Roblox defaults if omitted. See:
	  https://create.roblox.com/docs/reference/engine/classes/Attachment
]]

export type CharacterAttachmentRow = {
	name: string,
	partName: string,
	position: Vector3,
	axis: Vector3?,
	secondaryAxis: Vector3?,
}

-- Add one entry per attachment socket you need (VFX, audio, hitboxes, etc.).
local CHARACTER_ATTACHMENTS: { CharacterAttachmentRow } = {
	{ name = "MiddleFeetAttachment", partName = "HumanoidRootPart", position = Vector3.new(0, -3, 0) },
}

local CharacterAttachmentSetup = {}

function CharacterAttachmentSetup.Apply(character: Model)
	for _, row in CHARACTER_ATTACHMENTS do
		local limb = character:FindFirstChild(row.partName)
		if not limb or not limb:IsA("BasePart") then
			warn(
				string.format(
					"[CharacterAttachmentSetup] Missing part %q for attachment %q on %s",
					row.partName,
					row.name,
					character:GetFullName()
				)
			)
			continue
		end
		local existing = limb:FindFirstChild(row.name)
		if existing then
			if existing:IsA("Attachment") then
				existing:Destroy()
			else
				warn(
					string.format(
						"[CharacterAttachmentSetup] %q already exists on %s and is not an Attachment; skipping",
						row.name,
						limb:GetFullName()
					)
				)
				continue
			end
		end
		local a = Instance.new("Attachment")
		a.Name = row.name
		a.Position = row.position
		if row.axis then
			a.Axis = row.axis
		end
		if row.secondaryAxis then
			a.SecondaryAxis = row.secondaryAxis
		end
		a.Parent = limb
	end
end

return CharacterAttachmentSetup
