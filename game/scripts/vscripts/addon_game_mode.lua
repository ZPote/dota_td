-- lordsk_td

require("utils")

DEBUG_QUICK_START = true


if ModTD == nil then
	ModTD = class({})
	ModTD.hasRunOnce = false
end

function ModTD:ctor()
	self.init_pregame = false

	self.players = {}
	self.player_count = 0

	self.builder_units = {}
	self.builder_count = 0
end

function ModTD:InitGameMode()
	print("Template addon is loaded.")

	GameRules:SetPreGameTime(0.0)

	if DEBUG_QUICK_START then
		GameRules:SetCustomGameSetupTimeout(0.0)
		GameRules:SetCustomGameSetupRemainingTime(0.0)
		GameRules:SetCustomGameSetupAutoLaunchDelay(0.0)
		GameRules:SetHeroSelectionTime(0.0)

		local gameMode = GameRules:GetGameModeEntity()
		gameMode:SetCustomGameForceHero("dark_willow")
	end

	GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 0.5)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(ModTD, 'OnPlayerConnectFull')
		, self)

	print("[ModTD] mod loaded")
end

-- Evaluate the state of the game
function ModTD:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "Template addon script is running." )
	end

	if GameRules:State_Get() >= 7 and not self.init_pregame then -- >= pre_game
		self:OnGameStart()
	end

	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end

function ModTD:OnPlayerConnectFull(keys)
    deep_print(keys)
    local player = PlayerInstanceFromIndex(keys["userid"])
    player:SetTeam(DOTA_TEAM_FIRST)
end

function ModTD:OnGameStart()
	print("OnGameStart")

	-- find players
	for i=0,15 do
		local p = PlayerInstanceFromIndex(i)
		if p then
			self.players[self.player_count] = p
			self.player_count = self.player_count + 1
		end
	end

	printf("player_count=%d", self.player_count)

	-- find builders
	units = Entities:FindAllByClassname("npc_dota_building")
	for _,u in pairs(units) do
		if u:GetUnitName() == "td_builder" then
			self.builder_units[self.builder_count] = u
			self.builder_count = self.builder_count + 1
		end
	end

	printf("builder_count=%d", self.builder_count)

	assert(self.builder_count >= self.player_count)

	-- assign builders to players
	local bid = 0
	for _,p in pairs(self.players) do
		local b = self.builder_units[bid]
		b:SetOwner(p)
		b:SetTeam(DOTA_TEAM_GOODGUYS)
		b:SetControllableByPlayer(p:GetPlayerID(), false)
		bid = bid + 1
	end

	self.init_pregame = true
end


function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	if DEBUG_QUICK_START then
		PrecacheUnitByNameSync("npc_dota_hero_fark_willow", context)
	end
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = ModTD()
	GameRules.AddonTemplate:ctor()
	GameRules.AddonTemplate:InitGameMode()
	ModTD.hasRunOnce = true
end

function OnScriptReload()
	if ModTD.hasRunOnce then
		ModTD:ctor()
		ModTD:InitGameMode()
	end
end
OnScriptReload()