--!strict
-- MapMath: shared helpers for map/minimap coordinate transforms

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MinimapConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MinimapConfig"))

local MapMath = {}

function MapMath.worldToUV(worldPos: Vector3): Vector2
    return MinimapConfig.worldToUV(worldPos)
end

function MapMath.uvToWorld(uv: Vector2): Vector3
    return MinimapConfig.uvToWorld(uv)
end

function MapMath.uvToFullMapPosition(uv: Vector2): UDim2
    return UDim2.fromScale(1 - uv.X, 1 - uv.Y)
end

function MapMath.uvToMinimapContentPosition(uv: Vector2): UDim2
    return UDim2.fromScale(uv.X, uv.Y)
end

function MapMath.minimapPanForPlayerUV(playerUV: Vector2, zoomFactor: number): UDim2
    local offsetX = (playerUV.X - 0.5) * zoomFactor
    local offsetY = (playerUV.Y - 0.5) * zoomFactor
    return UDim2.fromScale(0.5 + offsetX, 0.5 + offsetY)
end

return MapMath

