ability_build_tower1_lua = class ({})

require("utils")
require("grid")

DEBUG_TOWER_SIZE = 128

function ability_build_tower1_lua:CastFilterResultLocation(pos)
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

function ability_build_tower1_lua:GetCustomCastErrorLocation(pos)
	--print("ability_build_tower1_lua:GetCustomCastErrorLocation()")
	return "#td_hud_error_location_blocked"
end

function ability_build_tower1_lua:OnSpellStart()
	--print("ability_build_tower1_lua:OnSpellStart()")
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

	CreateUnitByName("td_tower1", pos, false, self:GetCaster(), nil,
		DOTA_TEAM_GOODGUYS)
end