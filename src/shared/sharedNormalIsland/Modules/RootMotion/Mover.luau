--!strict

local RunService = game:GetService("RunService")

local ActiveMovementModule = require(script.Parent.ActiveMovement)
type ActiveMovement = ActiveMovementModule.ActiveMovement

export type Mover = {
	destroy: (self: Mover) -> (),
	cancelAll: (self: Mover) -> (),
	translate: (self: Mover, params: any) -> ActiveMovement,
	dash: (self: Mover, params: any) -> ActiveMovement,
	knockback: (self: Mover, params: any) -> ActiveMovement,
	pull: (self: Mover, params: any) -> ActiveMovement,
	launch: (self: Mover, params: any) -> ActiveMovement,
	slam: (self: Mover, params: any) -> ActiveMovement,
	float: (self: Mover, params: any) -> ActiveMovement,
	slide: (self: Mover, params: any) -> ActiveMovement,
	lunge: (self: Mover, params: any) -> ActiveMovement,
	teleport: (self: Mover, params: any) -> ActiveMovement,
	orbit: (self: Mover, params: any) -> ActiveMovement,
	springTo: (self: Mover, params: any) -> ActiveMovement,
	getRoot: (self: Mover) -> BasePart,
	getCharacter: (self: Mover) -> Model,
	getCachedMass: (self: Mover) -> number,
	acquireLinearVelocity: (self: Mover, owner: ActiveMovement, vectorVelocity: Vector3, maxForce: number) -> (),
	releaseLinearVelocity: (self: Mover, owner: ActiveMovement) -> (),
	acquireVectorForce: (self: Mover, owner: ActiveMovement, force: Vector3) -> (),
	releaseVectorForce: (self: Mover, owner: ActiveMovement) -> (),
	acquireAlignPosition: (
		self: Mover,
		owner: ActiveMovement,
		targetWorldPosition: Vector3,
		maxForce: number,
		maxVelocity: number,
		responsiveness: number,
		applyAtCenterOfMass: boolean
	) -> (),
	releaseAlignPosition: (self: Mover, owner: ActiveMovement) -> (),
	registerFrameUpdate: (self: Mover, owner: ActiveMovement, fn: (dt: number) -> ()) -> (),
	unregisterFrameUpdate: (self: Mover, owner: ActiveMovement) -> (),
	trackActive: (self: Mover, token: ActiveMovement) -> (),
	untrackActive: (self: Mover, token: ActiveMovement) -> (),
}

type FrameRow = {
	owner: ActiveMovement,
	fn: (dt: number) -> (),
}

export type MoverState = {
	_character: Model,
	_root: BasePart,
	_mass: number,
	_attachment: Attachment,
	_linearVelocity: LinearVelocity,
	_linearOwner: ActiveMovement?,
	_vectorForce: VectorForce,
	_vfOwner: ActiveMovement?,
	_alignPosition: AlignPosition,
	_apOwner: ActiveMovement?,
	_frameRows: { FrameRow },
	_heartbeat: RBXScriptConnection?,
	_tracked: { ActiveMovement },
	_destroyed: boolean,
}

local DEFAULT_ACCEL_MULT = 1000

local MT = {}

local function stealLinear(self: MoverState, owner: ActiveMovement)
	if self._linearOwner and self._linearOwner ~= owner then
		self._linearOwner:Cancel()
	end
end

local function stealVF(self: MoverState, owner: ActiveMovement)
	if self._vfOwner and self._vfOwner ~= owner then
		self._vfOwner:Cancel()
	end
end

local function stealAP(self: MoverState, owner: ActiveMovement)
	if self._apOwner and self._apOwner ~= owner then
		self._apOwner:Cancel()
	end
end

function MT.getRoot(self: MoverState): BasePart
	return self._root
end

function MT.getCharacter(self: MoverState): Model
	return self._character
end

function MT.getCachedMass(self: MoverState): number
	self._mass = self._root.AssemblyMass
	return self._mass
end

function MT.acquireLinearVelocity(self: MoverState, owner: ActiveMovement, vectorVelocity: Vector3, maxForce: number)
	stealLinear(self, owner)
	self._linearOwner = owner
	local lv = self._linearVelocity
	lv.VectorVelocity = vectorVelocity
	lv.MaxForce = maxForce
	lv.Enabled = true
end

function MT.releaseLinearVelocity(self: MoverState, owner: ActiveMovement)
	if self._linearOwner ~= owner then
		return
	end
	local lv = self._linearVelocity
	lv.Enabled = false
	lv.VectorVelocity = Vector3.zero
	self._linearOwner = nil
end

function MT.acquireVectorForce(self: MoverState, owner: ActiveMovement, force: Vector3)
	stealVF(self, owner)
	self._vfOwner = owner
	local vf = self._vectorForce
	vf.Force = force
	vf.Enabled = true
end

function MT.releaseVectorForce(self: MoverState, owner: ActiveMovement)
	if self._vfOwner ~= owner then
		return
	end
	local vf = self._vectorForce
	vf.Enabled = false
	vf.Force = Vector3.zero
	self._vfOwner = nil
end

function MT.acquireAlignPosition(
	self: MoverState,
	owner: ActiveMovement,
	targetWorldPosition: Vector3,
	maxForce: number,
	maxVelocity: number,
	responsiveness: number,
	applyAtCenterOfMass: boolean
)
	stealAP(self, owner)
	self._apOwner = owner
	local ap = self._alignPosition
	ap.Position = targetWorldPosition
	ap.MaxForce = maxForce
	ap.MaxVelocity = maxVelocity
	ap.Responsiveness = responsiveness
	ap.ApplyAtCenterOfMass = applyAtCenterOfMass
	ap.Enabled = true
end

function MT.releaseAlignPosition(self: MoverState, owner: ActiveMovement)
	if self._apOwner ~= owner then
		return
	end
	local ap = self._alignPosition
	ap.Enabled = false
	self._apOwner = nil
end

function MT.registerFrameUpdate(self: MoverState, owner: ActiveMovement, fn: (dt: number) -> ())
	self:unregisterFrameUpdate(owner)
	table.insert(self._frameRows, { owner = owner, fn = fn })
	self:_ensureHeartbeat()
end

function MT.unregisterFrameUpdate(self: MoverState, owner: ActiveMovement)
	for i = #self._frameRows, 1, -1 do
		if self._frameRows[i].owner == owner then
			table.remove(self._frameRows, i)
		end
	end
	self:_stopHeartbeatIfIdle()
end

function MT._ensureHeartbeat(self: MoverState)
	if self._heartbeat or self._destroyed then
		return
	end
	self._heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		if self._destroyed then
			return
		end
		local snapshot = table.clone(self._frameRows)
		for _, row in snapshot do
			if row.owner:IsActive() then
				row.fn(dt)
			end
		end
	end)
end

function MT._stopHeartbeatIfIdle(self: MoverState)
	if #self._frameRows > 0 then
		return
	end
	if self._heartbeat then
		self._heartbeat:Disconnect()
		self._heartbeat = nil
	end
end

function MT.trackActive(self: MoverState, token: ActiveMovement)
	table.insert(self._tracked, token)
end

function MT.untrackActive(self: MoverState, token: ActiveMovement)
	for i = #self._tracked, 1, -1 do
		if self._tracked[i] == token then
			table.remove(self._tracked, i)
		end
	end
end

function MT.cancelAll(self: MoverState)
	local snap = table.clone(self._tracked)
	for _, t in snap do
		if t:IsActive() then
			t:Cancel()
		end
	end
end

function MT.destroy(self: MoverState)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self:cancelAll()
	if self._heartbeat then
		self._heartbeat:Disconnect()
		self._heartbeat = nil
	end
	table.clear(self._frameRows)
	self._linearVelocity:Destroy()
	self._vectorForce:Destroy()
	self._alignPosition:Destroy()
	self._attachment:Destroy()
end

local function createMover(character: Model, movementBinders: { [string]: (Mover, any) -> ActiveMovement }): Mover
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		error('[RootMotion] Model must contain a BasePart named "HumanoidRootPart"')
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "RootMotion_Attachment"
	attachment.Parent = root

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "RootMotion_LinearVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.MaxForce = 0
	linearVelocity.Enabled = false
	linearVelocity.Parent = root

	local vectorForce = Instance.new("VectorForce")
	vectorForce.Name = "RootMotion_VectorForce"
	vectorForce.Attachment0 = attachment
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Force = Vector3.zero
	vectorForce.Enabled = false
	vectorForce.Parent = root

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = "RootMotion_AlignPosition"
	alignPosition.Attachment0 = attachment
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Position = root.Position
	alignPosition.MaxForce = 0
	alignPosition.MaxVelocity = 0
	alignPosition.Responsiveness = 10
	alignPosition.ApplyAtCenterOfMass = false
	alignPosition.Enabled = false
	alignPosition.Parent = root

	local self: MoverState = {
		_character = character,
		_root = root,
		_mass = root.AssemblyMass,
		_attachment = attachment,
		_linearVelocity = linearVelocity,
		_linearOwner = nil,
		_vectorForce = vectorForce,
		_vfOwner = nil,
		_alignPosition = alignPosition,
		_apOwner = nil,
		_frameRows = {},
		_heartbeat = nil,
		_tracked = {},
		_destroyed = false,
	}

	setmetatable(self, { __index = MT })

	local moverAny = self :: any
	for name, binder in movementBinders do
		moverAny[name] = function(_m: Mover, params: any): ActiveMovement
			return binder(self :: Mover, params)
		end
	end

	return self :: Mover
end

return {
	create = createMover,
	DEFAULT_ACCEL_MULT = DEFAULT_ACCEL_MULT,
}
