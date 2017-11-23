-- lordsk_td

require("utils")
require("grid")

DEBUG_QUICK_START = true
DEBUG_DRAW_GRID = false

if ModTD == nil then
	ModTD = class({})
	ModTD.hasRunOnce = false
	GameMode = nil

	GAMESTATE_BUILD_TIME = 0
	GAMESTATE_WAVE_SPAWN = 1
	GAMESTATE_WAVE_WAIT = 2

	UPDATE_DELTA = 1.0 -- can't be less than 1.0?
	DEF_BUILD_TIME = 10.0
end

function Waves_NewWave(wt)
	if wt.count == nil then
		wt.count = 0
		wt.step_count = {}
	end
	if wt.w == nil then
		wt.w = {}
	end
	
	wt.w[wt.count] = {}
	wt.count = wt.count + 1
end

function Waves_NewStep(wt, monsterName, monsterCount)
	local waveId = wt.count-1
	if wt.step_count[waveId] == nil then
		wt.step_count[waveId] = 0
	end

	local steps = wt.step_count[waveId]
	wt.w[waveId][steps] = { name=monsterName, count=monsterCount }
	wt.step_count[waveId] = steps + 1
end

function ModTD:ctor()
	self.init_pregame = false

	self.players = {}
	self.player_count = 0

	self.builder_units = {}
	self.builder_count = 0

	self.monster_spawns = {}
	self.monster_spawn_count = 0

	self.the_ancient = nil
	self.monsters = {}
	self.monster_count = 0

	self.waves = {}
	Waves_NewWave(self.waves)
		Waves_NewStep(self.waves, "td_monster_001", 10)
		Waves_NewStep(self.waves, "td_monster_001", 20)
		Waves_NewStep(self.waves, "td_monster_001", 15)
	Waves_NewWave(self.waves)
		Waves_NewStep(self.waves, "td_monster_001", 100)
		Waves_NewStep(self.waves, "td_monster_001", 1)
	----------------------------
	deep_print(self.waves)

	self.wave_id = 0
	self.wave_step_id = 0
	self.wave_monster_id = 0

	self.build_time = DEF_BUILD_TIME -- seconds
	self.state = GAMESTATE_BUILD_TIME
end

function ModTD:InitGameMode()
	print("Template addon is loaded.")

	GameRules:SetPreGameTime(0.0)
	GameMode = GameRules:GetGameModeEntity()
	GameMode:SetDaynightCycleDisabled(true)

	if DEBUG_QUICK_START then
		GameRules:SetCustomGameSetupTimeout(0.0)
		GameRules:SetCustomGameSetupRemainingTime(0.0)
		GameRules:SetCustomGameSetupAutoLaunchDelay(0.0)
		GameRules:SetHeroSelectionTime(0.0)

		GameMode:SetCustomGameForceHero("dark_willow")
	end

	GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", UPDATE_DELTA)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(ModTD, 'OnPlayerConnectFull')
		, self)

	-- LINK MODIFIERS
	LinkLuaModifier("modifier_builder", "modifier_builder", LUA_MODIFIER_MOTION_NONE)

	print("[ModTD] mod loaded")
end

-- Evaluate the state of the game
function ModTD:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "Template addon script is running." )
	end

	if GameRules:State_Get() >= 7 then -- >= pre_game
		if not self.init_pregame then
			self:OnGameStart()
		end
		self:OnGameUpdate()
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

	Grid:Init()

	-- find players
	for i=0,15 do
		local p = PlayerInstanceFromIndex(i)
		if p then
			self.players[self.player_count] = p
			self.player_count = self.player_count + 1
			p:SetTeam(DOTA_TEAM_GOODGUYS)
			ClearInventory(p:GetAssignedHero())
		end
	end

	printf("player_count=%d", self.player_count)

	-- find builders
	units = Entities:FindAllByClassname("npc_dota_building")
	for _,u in pairs(units) do
		if u:GetUnitName() == "td_builder" then
			self.builder_units[self.builder_count] = u
			self.builder_count = self.builder_count + 1
			u:AddNewModifier(u, nil, "modifier_builder", {})
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

	-- find spawns
	units = Entities:FindAllByName("monster_spawn_*")
	for _,u in pairs(units) do
		self.monster_spawns[self.monster_spawn_count] = u
		self.monster_spawn_count = self.monster_spawn_count + 1
		printf("monster_spawn%d", self.monster_spawn_count-1)
		deep_print(u)
	end

	units = Entities:FindAllByName("frone")
	for _,u in pairs(units) do
		self.the_ancient = u
		print("the_ancient", self.the_ancient:GetOrigin())
	end

	self.init_pregame = true
end

function ModTD:OnGameUpdate()
	--local firstAbility = hero:GetAbilityByIndex(0)
	--local curPos = firstAbility:GetCursorPosition()

	if DEBUG_DRAW_GRID then
		local p1 = self.players[0]
		local hero = p1:GetAssignedHero()
		if hero then
			local curPos = GetGroundPosition(hero:GetCenter(), hero)
			Grid:DebugDrawAround(curPos, 20, UPDATE_DELTA)
		end
	end

	self:HandleAliveMonsters()

	if self.state == GAMESTATE_BUILD_TIME then
		self.build_time = self.build_time - UPDATE_DELTA
		if self.build_time <= 0.0 then
			self.state = GAMESTATE_WAVE_SPAWN
		end

	elseif self.state == GAMESTATE_WAVE_SPAWN then
		GameRules:BeginTemporaryNight(UPDATE_DELTA * 3.0)
		self:SpawnWaveMonsters()

	elseif self.state == GAMESTATE_WAVE_WAIT then
		GameRules:BeginTemporaryNight(UPDATE_DELTA * 3.0)
		if self.monster_count <= 0 then
			self.wave_id = self.wave_id + 1
			self.build_time = DEF_BUILD_TIME
			self.state = GAMESTATE_BUILD_TIME
		end
		if self.wave_id >= self.waves.count then
			GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
		end
	end
end

function ModTD:HandleAliveMonsters()
	-- clear dead monsters, and attack click the the_ancient
	for i=0,self.monster_count-1 do
		while self.monsters[i] == nil or not self.monsters[i]:IsAlive() do
			self.monsters[i] = self.monsters[self.monster_count-1]
			self.monster_count = self.monster_count - 1
			if self.monster_count <= 0 then
				return
			end
		end

		if self.monster_count > 0 then
			self.monsters[i]:MoveToPositionAggressive(self.the_ancient:GetOrigin())
		end
	end
end

function ModTD:SpawnWaveMonsters()
	for s=0,self.monster_spawn_count-1 do
		printf("wave=%d step=%d monster_id=%d", self.wave_id, self.wave_step_id,
			self.wave_monster_id)

		local spawnPos = self.monster_spawns[s]:GetOrigin()
		local monsterName = self.waves.w[self.wave_id][self.wave_step_id].name
		local monster = CreateUnitByName(monsterName, spawnPos, true,
							nil, nil, DOTA_TEAM_BADGUYS)
		self.monsters[self.monster_count] = monster
		self.monster_count = self.monster_count + 1
		self.wave_monster_id = self.wave_monster_id + 1

		if self.wave_monster_id >= self.waves.w[self.wave_id][self.wave_step_id].count then
			self.wave_step_id = self.wave_step_id + 1
			self.wave_monster_id = 0
		end
		if self.wave_step_id >= self.waves.step_count[self.wave_id] then
			self:EndWave()
			print("End wave")
			return
		end
	end
end

function ModTD:EndWave()
	self.state = GAMESTATE_WAVE_WAIT
	self.wave_step_id = 0
	self.wave_monster_id = 0
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
		PrecacheUnitByNameSync("npc_dota_hero_dark_willow", context)
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