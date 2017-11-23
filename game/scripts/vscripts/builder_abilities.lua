--

require("utils")
require("grid")

DEBUG_TOWER_SIZE = 128

function CheckCast(pos)
	--printf("ability_build_tower1_lua:CastFilterResultLocation(pos=(%.2f, %.2f))",
	--	pos.x, pos.y)
	local bmin = {
		x = pos.x - DEBUG_TOWER_SIZE/2,
		y = pos.y - DEBUG_TOWER_SIZE/2
	}
	local bmax = {
		x = pos.x + DEBUG_TOWER_SIZE/2,
		y = pos.y + DEBUG_TOWER_SIZE/2
	}

	if not Grid:CanBuild(bmin, bmax) then
		Grid:DebugDrawAround(pos, 5, 1.5)
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function BuildTower(self)
	local pos = self:GetCursorPosition()

	local bmin = {
		x = pos.x - DEBUG_TOWER_SIZE/2,
		y = pos.y - DEBUG_TOWER_SIZE/2
	}
	local bmax = {
		x = pos.x + DEBUG_TOWER_SIZE/2,
		y = pos.y + DEBUG_TOWER_SIZE/2
	}

	Grid:Build(bmin, bmax)

	local towerName = self:GetAbilityKeyValues()["Tower"]
	CreateUnitByName(towerName, pos, false, self:GetCaster(), nil,
		DOTA_TEAM_GOODGUYS)
end

-- ability_build_tower1_lua
if ability_build_tower1_lua == nil then
	ability_build_tower1_lua = class ({})
end
function ability_build_tower1_lua:CastFilterResultLocation(pos)
	return CheckCast(pos)
end
function ability_build_tower1_lua:GetCustomCastErrorLocation(pos)
	return "#td_hud_error_location_blocked"
end
function ability_build_tower1_lua:OnSpellStart()
	BuildTower(self)
end

-- ability_build_tower2
if ability_build_tower2 == nil then
	ability_build_tower2 = class ({})
end
function ability_build_tower2:CastFilterResultLocation(pos)
	return CheckCast(pos)
end
function ability_build_tower2:GetCustomCastErrorLocation(pos)
	return "#td_hud_error_location_blocked"
end
function ability_build_tower2:OnSpellStart()
	BuildTower(self)
end