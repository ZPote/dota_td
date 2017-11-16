-- grid

require("utils")

if Grid == nil then
	Grid = class({})

	-- gridData enum
	BLOCKED = 0
	BUILDABLE = 1
end

function Grid:Init()
	self.cellSize = 64

	local worldMinX = GetWorldMinX()
	local worldMinY = GetWorldMinY()
	local worldMaxX = GetWorldMaxX()
	local worldMaxY = GetWorldMaxY()
	self.gridOriginX = worldMinX
	self.gridOriginY = worldMinY
	self.gridWidth = intDiv(worldMaxX - worldMinX, self.cellSize)
	self.gridHeight = intDiv(worldMaxY - worldMinY, self.cellSize)
	self.gridData = {} -- int[gridWidth * gridHeight]

	local SAMPLES_PER_CELL = 4

	for gy=0,self.gridHeight do
		for gx=0,self.gridWidth do

			-- sample cell diagonally and check map gridnav for blocked/traversable
			local cellData = BUILDABLE
			local sAdv = self.cellSize / SAMPLES_PER_CELL
			for s=0,SAMPLES_PER_CELL do
				local pos = Vector(
					self.gridOriginX + gx * self.cellSize + sAdv * s,
					self.gridOriginY + gy * self.cellSize + sAdv * s,
					0)
				if GridNav:IsBlocked(pos) or not GridNav:IsTraversable(pos) then
					cellData = BLOCKED
					break
				end
			end

			self.gridData[gy * self.gridWidth + gx] = cellData
		end
	end

	print("Grid initialized")
end

function Grid:DebugDrawAround(worldPos, squareRadius)
	local gx = intDiv(worldPos.x - self.gridOriginX, self.cellSize)
	local gy = intDiv(worldPos.y - self.gridOriginY, self.cellSize)

	for sy=-squareRadius,squareRadius do
		for sx=-squareRadius,squareRadius do
			local gsx = gx + sx
			local gsy = gy + sy
			local cellData = self.gridData[gsy * self.gridWidth + gsx]

			local color = {r = 0, g = 255, b = 0, a = 32}
			if cellData == BLOCKED then
				color = {r = 255, g = 0, b = 0, a = 32}
			end

			local pos = Vector(
					self.gridOriginX + gsx * self.cellSize,
					self.gridOriginY + gsy * self.cellSize,
					worldPos.z)
			pos = GetGroundPosition(pos, nil)

			DebugDrawBox(
				pos,
				Vector(0, 0, 0),
				Vector(self.cellSize, self.cellSize, 1),
				color.r, color.g, color.b, color.a,
				1.0)
		end
	end
end