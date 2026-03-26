--!strict

local ActiveMovement = require(script.Parent.Parent.ActiveMovement)
local Validation = require(script.Parent.Parent.Validation)
local Types = require(script.Parent.Parent.Types)
type Mover = Types.MoverInternal
type TeleportParams = Types.TeleportParams

local function run(mover: Mover, params: TeleportParams): ActiveMovement.ActiveMovement
	local root = mover:getRoot()
	local character = mover:getCharacter()
	local tFrame = params.target

	local token: ActiveMovement.ActiveMovement
	token = ActiveMovement.new(function()
		mover:untrackActive(token)
	end)

	mover:trackActive(token)

	if params.validatePath ~= false then
		local displacement = tFrame.Position - root.Position
		local pathParams: Types.ShapecastPathParams = {
			exclude = { character },
			collisionGroup = params.collisionGroup,
		}
		local res = Validation.shapecastPath(root.CFrame, displacement, root.Size, pathParams, character)
		local ox, oy, oz = tFrame:ToOrientation()
		root.CFrame = CFrame.new(res.safeCFrame.Position) * CFrame.fromOrientation(ox, oy, oz)
	else
		root.CFrame = tFrame
	end

	task.defer(function()
		if token:IsActive() then
			ActiveMovement.finish(token)
		end
	end)

	return token
end

return { run = run }
