--!strict

local req = require :: any
local root = script.Parent.Parent :: any
local ActiveMovement = req(root.ActiveMovement)
local Validation = req(root.Validation)

local function run(mover: any, params: any): any
	local rootPart = mover:getRoot()
	local character = mover:getCharacter()
	local tFrame = params.target

	local token: any
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
	end)

	mover:trackActive(token)

	if params.validatePath ~= false then
		local displacement = tFrame.Position - rootPart.Position
		local pathParams = {
			exclude = { character },
			collisionGroup = params.collisionGroup,
		}
		local res = Validation.shapecastPath(rootPart.CFrame, displacement, rootPart.Size, pathParams, character)
		local ox, oy, oz = tFrame:ToOrientation()
		rootPart.CFrame = CFrame.new(res.safeCFrame.Position) * CFrame.fromOrientation(ox, oy, oz)
	else
		rootPart.CFrame = tFrame
	end

	task.defer(function()
		if token:IsActive() then
			ActiveMovement.finish(token)
		end
	end)

	return token
end

return { run = run }
