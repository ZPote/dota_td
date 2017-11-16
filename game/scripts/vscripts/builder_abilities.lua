ability_build_tower1_lua = class ({})
--

require("utils")

function Ability_BuildTower1(event)
	print("Ability_BuildTower1():")
	deep_print(event)
end

function ability_build_tower1_lua:OnSpellStart()
	print("ability_build_tower1_lua:OnSpellStart()")
	local cursorPos = self:GetCursorPosition()
	CreateUnitByName("td_tower1", cursorPos, false, self:GetCaster(), nil,
	 DOTA_TEAM_GOODGUYS)
end