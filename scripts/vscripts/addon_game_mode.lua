--[[ Hero Demo game mode ]]
-- Note: Hero Demo makes use of some mode-specific Dota2 C++ code for its activation from the main Dota2 UI.  Regular custom games can't do this.

print( "Hero Demo game mode loaded." )

_G.NEUTRAL_TEAM = 4 -- global const for neutral team int
_G.DOTA_MAX_ABILITIES = 16
_G.HERO_MAX_LEVEL = 25

LinkLuaModifier( "lm_take_no_damage", "modifiers/lm_take_no_damage", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "dresser", "modifiers/dresser", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "flying", "modifiers/flying", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "no_health_bar", "modifiers/no_health_bar", LUA_MODIFIER_MOTION_NONE )

-- "demo_hero_name" is a magic term, "default_value" means no string was passed, so we'd probably want to put them in hero selection
-- sHeroSelection = GameRules:GetGameSessionConfigValue( "demo_hero_name", "default_value" )
-- 由于选择新英雄的功能有问题，为了快速测试，这里我直接改进入的选中英雄了
sHeroSelection = "npc_dota_hero_witch_doctor"
print( "sHeroSelection: " .. sHeroSelection )
------------------------------------------------------------------------------------------------------------------------------------------------------
-- HeroDemo class
------------------------------------------------------------------------------------------------------------------------------------------------------
if CHeroDemo == nil then
	_G.CHeroDemo = class({}) -- put CHeroDemo in the global scope
	--refer to: http://stackoverflow.com/questions/6586145/lua-require-with-global-local
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Required .lua files, which just exist to help organize functions contained in our addon.  Make sure to call these beneath the mode's class creation.
------------------------------------------------------------------------------------------------------------------------------------------------------
-- require('libraries/crash_detector')
require('libraries/debugger')
require( "events" )
require( "utility_functions" )
require('libraries/timers')
require('libraries/table')

require('libraries/wearable')

require('libraries/activity_modifier')
require('libraries/event_callback')
require('libraries/json')
require('libraries/notifications')
require('libraries/animations')

require('http')

-- require('internal/eventtest')
------------------------------------------------------------------------------------------------------------------------------------------------------
-- Precache files and folders
------------------------------------------------------------------------------------------------------------------------------------------------------
function Precache( context )
	PrecacheUnitByNameSync( sHeroSelection, context )
	PrecacheUnitByNameSync( "npc_dota_hero_axe", context )
	PrecacheUnitByNameSync( "npc_dota_hero_antimage", context )
	PrecacheUnitByNameSync( "npc_dota_hero_target_dummy", context )
	PrecacheResource( "particle", "particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_event_glitch.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_attack_crit.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/phantom_assassin_arcana_attack_blur.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/phantom_assassin_arcana_attack_blur_b.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_portrait_model.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_idle_rare.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_idle_rare.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/juggernaut/jugg_arcana/jugg_arcana_haste.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_teleport_model.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_teleport_end_model.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_death_model.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_loadout_rare_model.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/pudge/pudge_arcana/pudge_arcana_red_walk_groundscratch.vpcf", context)
	PrecacheResource( "particle", "particles/econ/items/pudge/pudge_arcana/pudge_arcana_red_idle_groundscratch.vpcf", context)
    PrecacheResource( "particle", "particles/econ/items/pudge/pudge_arcana/pudge_arcana_weapon_blur_right_to_left.vpcf", context)
    PrecacheResource( "particle", "particles/econ/items/warlock/warlock_lost_ores/golem_lores_hulk_swipe_left.vpcf", context)
    PrecacheResource( "particle", "particles/econ/items/warlock/warlock_lost_ores/golem_lores_hulk_swipe_right.vpcf", context)
    PrecacheResource( "particle", "particles/econ/items/axe/ti9_jungle_axe/ti9_axe_attack_left_blur.vpcf", context)
    PrecacheResource( "particle", "particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_culling_blade_cast.vpcf", context)
    PrecacheResource( "particle", "particles/econ/items/axe/ti9_jungle_axe/ti9_axe_attack_smash_blur_parent.vpcf", context)
    PrecacheResource( "particle", "particles/econ/items/axe/ti9_jungle_axe/ti9_axe_attack_blur.vpcf", context)
	PrecacheResource( "particle", "particles/ui_mouseactions/range_finder_cone.vpcf", context )
    PrecacheResource( "particle", "particles/econ/items/axe/ti9_jungle_axe/ti9_axe_attack_uppercut_blur.vpcf", context)
    PrecacheResource( "soundfile", "soundevents/game_sounds_custom.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_ui_imported.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/music/terrorblade_arcana/soundevents_stingers.vsndevts", context )
end

--------------------------------------------------------------------------------
-- Activate HeroDemo mode
--------------------------------------------------------------------------------
function Activate()
	-- When you don't have access to 'self', use 'GameRules.herodemo' instead
		-- example Function call: GameRules.herodemo:Function()
		-- example Var access: GameRules.herodemo.m_Variable = 1
    GameRules.herodemo = CHeroDemo()
    GameRules.herodemo:InitGameMode()
end

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
function CHeroDemo:InitGameMode()
	print( "Initializing Hero Demo mode" )
	local GameMode = GameRules:GetGameModeEntity()

	GameMode:SetCustomGameForceHero( sHeroSelection ) -- sHeroSelection string gets piped in by dashboard's demo button
	GameMode:SetTowerBackdoorProtectionEnabled( true )
	GameMode:SetFixedRespawnTime( 4 )
	--GameMode:SetBotThinkingEnabled( true ) -- the ConVar is currently disabled in C++
	-- Set bot mode difficulty: can try GameMode:SetCustomGameDifficulty( 1 )

	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetPreGameTime( 0 )
	GameRules:SetCustomGameSetupTimeout( 0 ) -- skip the custom team UI with 0, or do indefinite duration with -1

	GameMode:SetContextThink( "HeroDemo:GameThink", function() return self:GameThink() end, 0 )

	-- Events
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CHeroDemo, 'OnGameRulesStateChange' ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CHeroDemo, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_item_purchased", Dynamic_Wrap( CHeroDemo, "OnItemPurchased" ), self )
	ListenToGameEvent( "npc_replaced", Dynamic_Wrap( CHeroDemo, "OnNPCReplaced" ), self )
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CHeroDemo, 'OnEntityKilled'), self)
    ListenToGameEvent("player_chat",Dynamic_Wrap(CHeroDemo,"OnPlayerChat"),self)
    ListenToGameEvent("dota_non_player_used_ability", Dynamic_Wrap(CHeroDemo, 'On_dota_non_player_used_ability'), self)

	CustomGameEventManager:RegisterListener( "WelcomePanelDismissed", function(...) return self:OnWelcomePanelDismissed( ... ) end )
	CustomGameEventManager:RegisterListener( "RefreshButtonPressed", function(...) return self:OnRefreshButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "LevelUpButtonPressed", function(...) return self:OnLevelUpButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "MaxLevelButtonPressed", function(...) return self:OnMaxLevelButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "FreeSpellsButtonPressed", function(...) return self:OnFreeSpellsButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "NoCreepButtonPressed", function(...) return self:OnNoCreepButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "ToggleHideTree", function(...) return self:ToggleHideTree( ... ) end )
	CustomGameEventManager:RegisterListener( "ToggleHideBuilding", function(...) return self:ToggleHideBuilding( ... ) end )
	CustomGameEventManager:RegisterListener( "RespawnButtonPressed", function(...) return self:OnRespawnButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "SpawnEnemyButtonPressed", function(...) return self:OnSpawnEnemyButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "SpawnAllyButtonPressed", function(...) return self:OnSpawnAllyButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "LevelUpEnemyButtonPressed", function(...) return self:OnLevelUpEnemyButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "DummyTargetButtonPressed", function(...) return self:OnDummyTargetButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "CopySelection", function(...) return self:OnCopySelection( ... ) end )
	CustomGameEventManager:RegisterListener( "RemoveSelection", function(...) return self:OnRemoveSelection( ... ) end )
	CustomGameEventManager:RegisterListener( "LaneCreepsButtonPressed", function(...) return self:OnLaneCreepsButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "ChangeHeroButtonPressed", function(...) return self:OnChangeHeroButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "ChangeCosmeticsButtonPressed", function(...) return self:OnChangeCosmeticsButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "PauseButtonPressed", function(...) return self:OnPauseButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "LeaveButtonPressed", function(...) return self:OnLeaveButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "SwitchWearable", function(...) return self:OnSwitchWearable( ... ) end )
	CustomGameEventManager:RegisterListener( "SendToConsole", function(...) return self:SendToConsole( ... ) end )
	CustomGameEventManager:RegisterListener( "SendToServerConsole", function(...) return self:SendToServerConsole( ... ) end )
	CustomGameEventManager:RegisterListener( "Taunt", Dynamic_Wrap(CHeroDemo, "Taunt"))
    CustomGameEventManager:RegisterListener( "ResetGems", Dynamic_Wrap(CHeroDemo, "OnResetGems"))
    CustomGameEventManager:RegisterListener( "CheckGemLoop", Dynamic_Wrap(CHeroDemo, "OnCheckGemLoop"))
    CustomGameEventManager:RegisterListener( "CheckGemVip", Dynamic_Wrap(CHeroDemo, "OnCheckGemVip"))
    CustomGameEventManager:RegisterListener( "SwitchTinyModel", Dynamic_Wrap(CHeroDemo, "OnSwitchTinyModel"))
    
	EventCallback:RegisterHandler("SwitchPrismatic", function(...) return self:OnSwitchPrismatic( ... ) end)
	EventCallback:RegisterHandler("ToggleEthereal", function(...) return self:OnToggleEthereal( ... ) end)
    EventCallback:RegisterHandler("WearCombination", function(...) return self:OnWearCombination( ... ) end)
    EventCallback:RegisterHandler("SwitchCourier", function(...) return self:OnWearCourier( ... ) end)
    EventCallback:RegisterHandler("SwitchWard", function(...) return self:OnWearWard( ... ) end)

    EventCallback:RegisterAsyncHandler("Vote", function(...) return self:OnVote( ... ) end)
    EventCallback:RegisterAsyncHandler("VoteCombination", function(...) return self:OnVoteCombination( ... ) end)
    EventCallback:RegisterAsyncHandler("RequestCombination", function(...) return self:OnRequestCombination( ... ) end)
    EventCallback:RegisterAsyncHandler("RequestComments", function(...) return self:OnRequestComments( ... ) end)
    EventCallback:RegisterAsyncHandler("LoadMoreComments", function(...) return self:OnLoadMoreComments( ... ) end)
    EventCallback:RegisterAsyncHandler("SubmitComment", function(...) return self:OnSubmitComment( ... ) end)
    EventCallback:RegisterAsyncHandler("CommendComment", function(...) return self:OnCommendComment( ... ) end)
    EventCallback:RegisterAsyncHandler("CreateOrder", function(...) return self:OnCreateOrder( ... ) end)
    EventCallback:RegisterAsyncHandler("RefreshGems", function(...) return self:OnRefreshGems( ... ) end)
    
    GameMode:SetModifierGainedFilter(Dynamic_Wrap(CHeroDemo, "ModifierGainedFilter"), self)
    GameMode:SetTrackingProjectileFilter(Dynamic_Wrap(CHeroDemo, "TrackingProjectileFilter"), self)

	SendToServerConsole( "sv_cheats 1" )
	SendToServerConsole( "dota_hero_god_mode 0" )
	SendToServerConsole( "dota_ability_debug 0" )
	SendToServerConsole( "dota_creeps_no_spawning 0" )
	SendToServerConsole( "dota_easybuy 1" )
	--SendToServerConsole( "dota_bot_mode 1" )

	self.m_sHeroSelection = sHeroSelection -- this seems redundant, but events.lua doesn't seem to know about sHeroSelection

	self.m_bPlayerDataCaptured = false
	self.m_nPlayerID = 0

	--self.m_nHeroLevelBeforeMaxing = 1 -- unused now
	--self.m_bHeroMaxedOut = false -- unused now
	
	self.m_nALLIES_TEAM = 2
	self.m_tAlliesList = {}
	self.m_nAlliesCount = 0

	self.m_nENEMIES_TEAM = 3
	self.m_tEnemiesList = {}

    self.m_bFreeSpellsEnabled = false
    self.m_bNoCreep = false
    self.bHideTree = false
    self.bHideBuilding = false
	self.m_bInvulnerabilityEnabled = false
	self.m_bCreepsEnabled = true
    self.m_sHeroToSpawn = "npc_dota_hero_axe" 
    self.m_bRespawnWear = false
    _G.GemVips = {}

	local hNeutralSpawn = Entities:FindByName( nil, "neutral_caster_spawn" )
	if ( hNeutralSpawn == NIL ) then
		hNeutralSpawn = Entities:CreateByClassname( "info_target" );
	end

	self._hNeutralCaster = CreateUnitByName( "npc_dota_neutral_caster", hNeutralSpawn:GetAbsOrigin(), false, nil, nil, NEUTRAL_TEAM )
	

	PlayerResource:SetCustomTeamAssignment( self.m_nPlayerID, self.m_nALLIES_TEAM ) -- put PlayerID 0 on Radiant team (== team 2)

	require( "scripts/vscripts/libraries/vector_target/vector_target" )
	require( "scripts/vscripts/libraries/filters/filters" )
	require( "scripts/vscripts/libraries/talent/talent" )
	FilterManager:Init()
end

--------------------------------------------------------------------------------
-- Main Think
--------------------------------------------------------------------------------
function CHeroDemo:GameThink()
--    print( "#self.m_tEnemiesList == " .. #self.m_tEnemiesList .. " | GameTime == " .. tostring( string.format( "%.0f", GameRules:GetGameTime() ) ) )
    local a = 1
    local b = {}
    b.c = 2
    --   print("1")
    f()

	return 0.5
end

function f()
    local a = 1
    local b = {}
    b.c = 2
    -- print("f")
    -- print("f")
end