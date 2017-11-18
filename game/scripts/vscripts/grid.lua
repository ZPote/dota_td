-- grid

require("utils")

if Grid == nil then
	--print("NEW GRID", _G)
	Grid = class({})
	Grid.initialized = false

	-- gridData enum
	BUILDABLE = 0
	BLOCKED = 1
	BLOCKED_BUILDING = 2
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

	local SAMPLES_PER_CELL2 = 2

	for gy=0,self.gridHeight-1 do
		for gx=0,self.gridWidth-1 do

			-- sample cell diagonally and check map gridnav for blocked/traversable
			local cellData = BUILDABLE
			local sAdv = self.cellSize / SAMPLES_PER_CELL2
			for sx=1,SAMPLES_PER_CELL2 do
				for sy=1,SAMPLES_PER_CELL2 do
					local pos = Vector(
						self.gridOriginX + gx * self.cellSize + sAdv * sx,
						self.gridOriginY + gy * self.cellSize + sAdv * sy,
						0)
					if GridNav:IsBlocked(pos) or not GridNav:IsTraversable(pos) then
						cellData = BLOCKED
						break
					end
				end
			end

			self.gridData[gy * self.gridWidth + gx] = cellData
		end
	end

	-- note: class is trigger_hero on a mesh
	-- find block volumes
	volumes = Entities:FindAllByName("volume_nobuild*") 
	for _,u in pairs(volumes) do
		print("volume found")
		local bmin = u:GetBoundingMins()
		local bmax = u:GetBoundingMaxs()
		local origin = u:GetAbsOrigin()
		bmin.x = bmin.x + origin.x
		bmin.y = bmin.y + origin.y
		bmax.x = bmax.x + origin.x
		bmax.y = bmax.y + origin.y

		--printf("start=[%.2f, %.2f] bmax=[%.2f, %.2f]",
		--	bmin.x, bmin.y, bmax.x, bmax.y)

		local startGx = intDiv(bmin.x - self.gridOriginX, self.cellSize)
		local startGy = intDiv(bmin.y - self.gridOriginY, self.cellSize)
		local endGx = intDiv(bmax.x - self.gridOriginX, self.cellSize)
		local endGy = intDiv(bmax.y - self.gridOriginY, self.cellSize)

		--printf("start=[%d, %d] end=[%d, %d]", startGx, startGy, endGx, endGy)
		for gy=startGy,endGy do
			for gx=startGx,endGx do
				self.gridData[gy * self.gridWidth + gx] = BLOCKED
			end
		end
	end

	self.initialized = true
	print("Grid initialized")
end

function Grid:DebugDrawAround(worldPos, squareRadius, duration)
	if not self.initialized then
		return
	end

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
			if cellData == BLOCKED_BUILDING then
				color = {r = 0, g = 0, b = 255, a = 32}
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
				duration)
		end
	end
end

function Grid:CanBuild(absBmin, absBmax)
	-- NOTE: When hovering (not clicking to cast),
	-- _G is different so Gird is not initialized
	if not self.initialized then
		return true
	end

	local startGx = intDiv(absBmin.x - self.gridOriginX, self.cellSize)
	local startGy = intDiv(absBmin.y - self.gridOriginY, self.cellSize)
	local endGx = intDiv(absBmax.x - self.gridOriginX, self.cellSize)
	local endGy = intDiv(absBmax.y - self.gridOriginY, self.cellSize)

	for gy=startGy,endGy do
		for gx=startGx,endGx do
			if self.gridData[gy * self.gridWidth + gx] ~= BUILDABLE then
				return false
			end
		end
	end

	return true
end

function Grid:Build(absBmin, absBmax)
	if not self.initialized then
		return false
	end

	local startGx = intDiv(absBmin.x - self.gridOriginX, self.cellSize)
	local startGy = intDiv(absBmin.y - self.gridOriginY, self.cellSize)
	local endGx = intDiv(absBmax.x - self.gridOriginX, self.cellSize)
	local endGy = intDiv(absBmax.y - self.gridOriginY, self.cellSize)

	for gy=startGy,endGy do
		for gx=startGx,endGx do
			self.gridData[gy * self.gridWidth + gx] = BLOCKED_BUILDING
		end
	end
end