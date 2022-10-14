-- Created by Elfansoer
--[[
-- 巫蛊诅咒效果，停留在敌方身上
]]

-- 测试
require "utility_functions"
--------------------------------------------------------------------------------
modifier_witch_doctor_maledict_lua_normal = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_maledict_lua_normal:IsHidden()
	return false
end

function modifier_witch_doctor_maledict_lua_normal:IsDebuff()
	return true
end

function modifier_witch_doctor_maledict_lua_normal:IsPurgable()
	return false
end

function modifier_witch_doctor_maledict_lua_normal:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_maledict_lua_normal:OnCreated( kv )
	-- references
	self.damage = kv.damage
	self.curTick = 0
	self.totalTick = 12
	print("modifier_witch_doctor_maledict_lua_normal:OnCreated()")
    self:PlayEffects(self:GetParent())
	if not IsServer() then return end
	-- Play effects
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
function modifier_witch_doctor_maledict_lua_normal:OnIntervalThink()
	-- 普通伤害没有特效
	if self.curTick < self.totalTick then
		ApplyDamage(self.damageTable)
	end
	self.curTick = self.curTick + 1
end

-- buff叠加时会调用
function modifier_witch_doctor_maledict_lua_normal:OnRefresh( kv )
	if not IsServer() then return end
    self.curTick = 0
end

function modifier_witch_doctor_maledict_lua_normal:OnRemoved()
end

function modifier_witch_doctor_maledict_lua_normal:OnDestroy()
    print("modifier_witch_doctor_maledict_lua_normal:OnDestroy()")
	-- 移除特效
	if self.spell_effect then
		ParticleManager:ReleaseParticleIndex( self.spell_effect )
		ParticleManager:DestroyParticle(self.spell_effect,false)
	end
	-- Play effects
	local sound_loop = "Hero_WitchDoctor.Maledict_Loop"
	StopSoundOn( sound_loop, self:GetParent())
	if not IsServer() then return end
	self:StartIntervalThink( -1 )
end
--[[
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_witch_doctor_maledict_lua_normal:DeclareFunctions()
	local funcs = {
		-- MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,   -- = 86
        -- Method Name: `GetModifierConstantHealthRegen`
        -- MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, -- = 87
        -- Method Name: `GetModifierHealthRegenPercentage`
	}

	return funcs
end

function modifier_witch_doctor_maledict_lua_normal:GetModifierConstantHealthRegen( params )
    	

	return self.heal
end
]]
--------------------------------------------------------------------------------
-- Graphics & Animations

function modifier_witch_doctor_maledict_lua_normal:GetEffectName()
	return "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_dot.vpcf"
    -- return "particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_aura.vpcf"
end

function modifier_witch_doctor_maledict_lua_normal:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

-- 普通伤害的特效是创建时播放，持续12秒
function modifier_witch_doctor_maledict_lua_normal:PlayEffects(target )
	print("target is:",target:GetClassname())
	-- PrintTable(target)
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_dot.vpcf"
	-- Create Particle
	-- 因为粒子中配置了 movement lock to control point 所以脚本中必须将粒子绑定到controlEntity,且初始绑定类型为 PATTACH_ABSORIGIN
	-- 初始绑定类型为 PATTACH_CUSTOMORIGIN ，PATTACH_ABSORIGIN_FOLLOW 角色身上有特效残留
	-- 初始绑定类型为 PATTACH_WORLDORIGIN 时 ，身上不会有残留，但是在坐标原点仍然残留有特效
	-- 这是整体测试下来的结果，但是不知道具体原因
	--self.spell_effect = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	self.spell_effect = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, nil )
	ParticleManager:SetParticleControlEnt( self.spell_effect, 0, target, PATTACH_POINT_FOLLOW, "root", Vector(0,0,0), true )

	--self.spell_effect = ParticleManager:CreateParticle( particle_cast, PATTACH_ROOTBONE_FOLLOW , target )
	ParticleManager:ReleaseParticleIndex( self.spell_effect )

	-- 这里为什么会提示 target:GetOrigin() 不存在？
	-- ParticleManager:SetParticleControl( self.spell_effect, 0, target:GetOrigin() )
	-- Create Sound
	--[[
	-- 现在已经不播放了
	local sound_loop = "Hero_WitchDoctor.Maledict_Loop"
    EmitSoundOn( sound_loop, self:GetParent() )
	]]
end