phoenix_supernova_lua = class({})
LinkLuaModifier( "modifier_phoenix_supernova_lua_hide_effect", "lua_abilities/phoenix_supernova_lua/modifier_phoenix_supernova_lua_hide_effect", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_phoenix_supernova_lua_egg_thinker", "lua_abilities/phoenix_supernova_lua/modifier_phoenix_supernova_lua_egg_thinker", LUA_MODIFIER_MOTION_NONE )

function phoenix_supernova_lua:IsHiddenWhenStolen() 	return false end
function phoenix_supernova_lua:IsRefreshable() 			return true end
function phoenix_supernova_lua:IsStealable() 			return true end
function phoenix_supernova_lua:IsNetherWardStealable() 	return false end

function phoenix_supernova_lua:GetCastRange() 	return self:GetSpecialValueFor("cast_range") end


function phoenix_supernova_lua:GetIntrinsicModifierName()
	return "modifier_phoenix_supernova_scepter_passive"
end

function phoenix_supernova_lua:OnSpellStart()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self
	local location = caster:GetAbsOrigin()
	local egg_duration = self:GetDuration()

	local max_attack = self:GetSpecialValueFor("max_hero_attacks")

    -- 给自己添加隐身无敌等诸多状态
	caster:AddNewModifier(caster, ability, "modifier_phoenix_supernova_lua_hide_effect", {duration = egg_duration })
    -- 创建蛋
    local egg = CreateUnitByName("npc_dota_phoenix_sun",location,false,caster,caster:GetOwner(),caster:GetTeamNumber())
	egg:AddNewModifier(caster, ability, "modifier_phoenix_supernova_lua_egg_thinker", {
        duration = egg_duration + 1, -- 蛋的timer更长
        reborn_time = egg_duration,
    })

    egg.max_attack = max_attack
	egg.current_attack = 0

    -- 播放蛋的运动效果？
	local egg_playback_rate = 6 / egg_duration
	egg:StartGestureWithPlaybackRate(ACT_DOTA_IDLE , egg_playback_rate)

	caster.egg = egg

    -- 后面是蓝杖逻辑
    if not caster:HasScepter() then return end
	caster.ally = self:GetCursorTarget()
	if caster.ally == caster then
		caster.ally = nil
	else
		local ally = caster.ally
        ally:AddNewModifier(caster, ability, "modifier_phoenix_supernova_lua_hide_effect", {duration = egg_duration})
        ally:SetAbsOrigin(caster:GetAbsOrigin())
	end
end

function phoenix_supernova_lua:GetBehavior()
    local caster = self:GetCaster()
    if caster:HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
	end
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
end