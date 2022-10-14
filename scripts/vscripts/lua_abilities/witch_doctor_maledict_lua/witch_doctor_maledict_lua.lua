witch_doctor_maledict_lua = class({})
LinkLuaModifier( "modifier_witch_doctor_maledict_lua_normal", "lua_abilities/witch_doctor_maledict_lua/modifier_witch_doctor_maledict_lua_normal", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_witch_doctor_maledict_lua_burst", "lua_abilities/witch_doctor_maledict_lua/modifier_witch_doctor_maledict_lua_burst", LUA_MODIFIER_MOTION_NONE )
--[[
    -- 通过参考水晶室女的 冰霜新星 来学习制作区域目标施法的技能
]]
--------------------------------------------------------------------------------
-- AOE Radius
function witch_doctor_maledict_lua:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
-- Ability Start
function witch_doctor_maledict_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local bonus_damage = self:GetSpecialValueFor("bonus_damage") -- 爆发伤害，已损失生命值的百分比
	local radius = self:GetSpecialValueFor("radius")
	local bonus_damage_threshold = self:GetSpecialValueFor("bonus_damage_threshold")
    local ticks = self:GetSpecialValueFor("ticks")

    local debuffDuration = 12
    local _normalDamageTick = 1
    local _burstDamageTick = 3.97


	--local vision_radius = 900
	--local vision_duration = 6

	-- Find Units in Radius
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		point,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO,	-- int, type filter
		-- DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS,	-- int, flag filter 不会作用于技能免疫、无敌和隐藏单位
		0,
        0,	-- int, order filter
		false	-- bool, can grow cache
	)

	-- Precache damage	 
	local damageTable = {
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
	}
    local enemy_count = 0
	for _,enemy in pairs(enemies) do
		-- Apply damage
		--damageTable.victim = enemy
		--ApplyDamage(damageTable)
        -- 爆发伤害取决于施法时目标的生命值，而不是产生爆发伤害时。
        local burst_damage = bonus_damage * (enemy:GetMaxHealth()-enemy:GetHealth()) / 100.0
		-- Add modifier
        -- 添加普通伤害修改器
		enemy:AddNewModifier(
			caster, -- player source
			self, -- ability source
			"modifier_witch_doctor_maledict_lua_normal", -- modifier name
			{ duration = debuffDuration,
              damage = self:GetAbilityDamage(),
              tick = _normalDamageTick,
            } -- kv
		)
        -- 添加爆发伤害修改器
		enemy:AddNewModifier(
			caster, -- player source
			self, -- ability source
			"modifier_witch_doctor_maledict_lua_burst", -- modifier name
			{ duration = debuffDuration,
              damage = burst_damage,
              tick = _burstDamageTick,
            } -- kv
		)
        enemy_count = enemy_count + 1
	end

    -- 巫医的巫蛊诅咒不提供视野
	-- AddFOWViewer( self:GetCaster():GetTeamNumber(), point, vision_radius, vision_duration, true )

	self:PlayEffects( point, radius,enemy_count > 0)
end

--------------------------------------------------------------------------------
-- Ability Considerations
function witch_doctor_maledict_lua:AbilityConsiderations()
	-- Scepter
	local bScepter = caster:HasScepter()

	-- Linken & Lotus
	local bBlocked = target:TriggerSpellAbsorb( self )

	-- Break
	local bBroken = caster:PassivesDisabled()

	-- Advanced Status
	local bInvulnerable = target:IsInvulnerable()
	local bInvisible = target:IsInvisible()
	local bHexed = target:IsHexed()
	local bMagicImmune = target:IsMagicImmune()

	-- Illusion Copy
	local bIllusion = target:IsIllusion()
end

--------------------------------------------------------------------------------
function witch_doctor_maledict_lua:PlayEffects( point, radius,success)
	-- Get Resources
	-- local particle_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict.vpcf"
	local sound_cast = success and "Hero_WitchDoctor.Maledict_Cast" or "Hero_WitchDoctor.Maledict_CastFail"

    local particle1_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_g.vpcf"
    local particle2_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_j.vpcf"
    local particle3_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_light.vpcf"
	-- Create Particle
	local effect1_cast = ParticleManager:CreateParticle( particle1_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect1_cast, 0, point)
	ParticleManager:ReleaseParticleIndex( effect1_cast )
	-- Create Particle
	local effect2_cast = ParticleManager:CreateParticle( particle2_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect2_cast, 0, point)
	ParticleManager:ReleaseParticleIndex( effect2_cast )
	-- Create Particle
	local effect3_cast = ParticleManager:CreateParticle( particle3_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect3_cast, 0, point)
	ParticleManager:ReleaseParticleIndex( effect3_cast )
	-- Create Sound
	EmitSoundOnLocationWithCaster( point, sound_cast, self:GetCaster() )
end