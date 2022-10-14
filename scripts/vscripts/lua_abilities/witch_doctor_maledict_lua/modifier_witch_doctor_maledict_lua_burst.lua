-- Created by Elfansoer
--[[
-- 巫蛊诅咒效果，爆发伤害，隐藏
]]
--------------------------------------------------------------------------------
modifier_witch_doctor_maledict_lua_burst = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_maledict_lua_burst:IsHidden()
	return true
end

function modifier_witch_doctor_maledict_lua_burst:IsDebuff()
	return true
end

function modifier_witch_doctor_maledict_lua_burst:IsPurgable()
	return false
end

function modifier_witch_doctor_maledict_lua_burst:GetAttributes()
    -- 这个要验证一下，是否仅施法时忽略无敌单位？
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_maledict_lua_burst:OnCreated( kv )
    -- references
	self.curTick = 0
	self.totalTick = 3
    self.tick = kv.tick
	if not IsServer() then return end
	-- Play effects
	--local sound_cast = "Hero_Medusa.ManaShield.On"
	--EmitSoundOn( sound_cast, self:GetParent() )
    print("modifier_witch_doctor_maledict_lua_normal:OnCreated()")
    -- 官方的组合资源有问题，脚本不能直接调用，所以需要脚本自己组合，在Think时调用
    -- self:PlayEffects(self:GetParent())
	self.caster = self:GetAbility():GetCaster()
	-- precache damage
	self.damageTable = {
		victim = self:GetParent(),
		attacker = self.caster,
		damage = kv.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(), --Optional.
	}
	-- Start interval
	-- 每隔一段时间产生一次普通伤害
	self:StartIntervalThink(kv.tick)
end

-- Interval Effects
function modifier_witch_doctor_maledict_lua_burst:OnIntervalThink()
	-- 爆发伤害有特效
    self:PlayEffects(self:GetParent())

	if self.curTick < self.totalTick then
		ApplyDamage(self.damageTable)
	end
    self.curTick = self.curTick + 1
end

-- 技能升级时会调用
function modifier_witch_doctor_maledict_lua_burst:OnRefresh( kv )
	-- references
	if not IsServer() then return end
    self.curTick = 0
end

function modifier_witch_doctor_maledict_lua_burst:OnRemoved()
end

function modifier_witch_doctor_maledict_lua_burst:OnDestroy()
    print("modifier_witch_doctor_maledict_lua_burst:OnDestroy()")
	if not IsServer() then return end
	-- Play effects
	-- local sound_cast = "Hero_Medusa.ManaShield.Off"
	-- EmitSoundOn( sound_cast, self:GetParent() )

    -- 移除特效
    -- ParticleManager:DestroyParticle(self.spell_effect,false)
	self:StartIntervalThink( -1 )
end
--[[
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_witch_doctor_maledict_lua_burst:DeclareFunctions()
	local funcs = {
		-- MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,   -- = 86
        -- Method Name: `GetModifierConstantHealthRegen`
        -- MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, -- = 87
        -- Method Name: `GetModifierHealthRegenPercentage`
	}

	return funcs
end

function modifier_witch_doctor_maledict_lua_burst:GetModifierConstantHealthRegen( params )
    	

	return self.heal
end
]]
--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_witch_doctor_maledict_lua_burst:GetEffectName()
	return "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_j.vpcf"
    -- return "particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_aura.vpcf"
end

function modifier_witch_doctor_maledict_lua_burst:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_witch_doctor_maledict_lua_burst:PlayEffects(target )
	-- Get Resources
	-- local particle_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict.vpcf"
    local particle1_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_g.vpcf"
    local particle2_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_j.vpcf"
    local particle3_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_light.vpcf"
	-- Create Particle
	local effect1_cast = ParticleManager:CreateParticle( particle1_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:ReleaseParticleIndex( effect1_cast )
	-- Create Particle
	local effect2_cast = ParticleManager:CreateParticle( particle2_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:ReleaseParticleIndex( effect2_cast )
	-- Create Particle
	local effect3_cast = ParticleManager:CreateParticle( particle3_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:ReleaseParticleIndex( effect3_cast )
    
    -- 与施法特效样式一致，但音效不同
    local sound_tick = "Hero_WitchDoctor.Maledict_Tick"
    EmitSoundOn( sound_tick, self:GetParent())
	-- Create Particle
    --[[
    -- OnCreate 调用 witchdoctor_maledict.vpcf 时才设置1号控制点
	self.spell_effect = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	-- ParticleManager:SetParticleAlwaysSimulate(self.spell_effect)
	ParticleManager:SetParticleControlEnt( self.spell_effect, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "root", Vector(0,0,0), true )
	ParticleManager:SetParticleControl( self.spell_effect, 1, Vector( self.tick, 0, 0 ) ) -- 设置控制点,tick秒后播放下一次循环
	ParticleManager:ReleaseParticleIndex( self.spell_effect )

    -- 删除逻辑另外执行
    self:SetContextThink(DoUniqueString("EffectAreaShow"),function()
        ParticleManager:ReleaseParticleIndex(effect_cast)
        ParticleManager:DestroyParticle(effect_cast,false)
    end,self.duaration)
    ]]
end