-- Created by Elfansoer
--[[
-- 巫毒治疗术
]]
--------------------------------------------------------------------------------
modifier_witch_doctor_voodoo_restoration_lua = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_voodoo_restoration_lua:IsHidden()
	return false
end

function modifier_witch_doctor_voodoo_restoration_lua:IsDebuff()
	return false
end

function modifier_witch_doctor_voodoo_restoration_lua:IsPurgable()
	return false
end

function modifier_witch_doctor_voodoo_restoration_lua:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_voodoo_restoration_lua:OnCreated( kv )
	-- references
	self.mana_per_second = self:GetAbility():GetSpecialValueFor( "mana_per_second" )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.heal = self:GetAbility():GetSpecialValueFor( "heal" )
    self.heal_interval = self:GetAbility():GetSpecialValueFor( "heal_interval" )
	self.enemy_damage_pct = self:GetAbility():GetSpecialValueFor( "enemy_damage_pct" )/100

	if not IsServer() then return end
	-- Play effects
	local sound_cast = "Hero_Medusa.ManaShield.On"
	EmitSoundOn( sound_cast, self:GetParent() )
    print("modifier_witch_doctor_voodoo_restoration_lua:OnCreated()")
    self:PlayEffects(self:GetParent())

	self.caster = self:GetAbility():GetCaster()
	-- precache damage
	self.damageTable = {
		-- victim = target,
		attacker = self.caster,
		damage = self.heal * self.enemy_damage_pct,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(), --Optional.
	}

	-- Start interval
	-- 时间间隔填固定值了
	self:StartIntervalThink( self.heal_interval )
	self:OnIntervalThink()
	-- 技能开启时是否真的有一次救己伤敌效果？
	-- self:ApplyDamageOnSpellStart()
end

-- 实际上技能里首次没有伤害，第一次效果在0.33秒后执行
function modifier_witch_doctor_voodoo_restoration_lua:ApplyDamageOnSpellStart()
	local around_units = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_BOTH ,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC ,	-- 英雄，小兵，中立单位，信使
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	for _,target in pairs(around_units) do
		local caster = self:GetAbility():GetCaster()
		if target:IsAlive() then
			if caster:GetTeamNumber() == target:GetTeamNumber() then
				-- 救己
				target:Heal( self.heal, self:GetAbility() )
			else
				-- 伤敌
				self.damageTable.victim = target
				ApplyDamage( self.damageTable )
			end
		end
	end
end

-- Interval Effects
function modifier_witch_doctor_voodoo_restoration_lua:OnIntervalThink()
	-- 技能开启时，添加一个计时器，每秒消耗魔法，造成范围伤害和治疗，
	-- 光环的0.5秒粘滞时间表示光环消失后仍然持续0.5秒，
	-- 实现逻辑是以每跳小于0.5秒的时间（比如0.33秒）添加一个持续0.5秒的子效果（覆盖不叠加），当光环移除时，子效果仍然能停留最多0.5秒
	-- 由于所有效果由光环提供，所以逻辑应该是，添加光环后，由光环计算伤害和治疗
	local caster = self:GetCaster()
	-- 获取周围的单位列表
	local around_units = FindUnitsInRadius(
		caster:GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_BOTH ,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC ,	-- 英雄，小兵，中立单位，信使；伤害不包括信使，暂时就这样写了
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	for _,around_unit in pairs(around_units) do
		around_unit:AddNewModifier(
			self.caster, -- player source
			self:GetAbility(), -- ability source
			"modifier_witch_doctor_voodoo_restoration_lua_thinker", -- modifier name
			{ 
				duration = 0.5,
				heal_interval = self.heal_interval,
				heal = self.heal,
				damage = self.heal * self.enemy_damage_pct,
				damage_type = DAMAGE_TYPE_MAGICAL,
				-- HSCRIPT argument unsupported in Script_AddNewModifier table kv表不支持配置table
				-- damageTable = self.damageTable
			} -- kv
		)
	end

	-- 消耗魔法
	caster:SpendMana(self.mana_per_second,self:GetAbility())
	-- 剩余魔法如果不够消耗，则关闭技能
	if caster:GetMana() < self.mana_per_second then
		self:GetAbility():ToggleAbility()
	end
	print("OnIntervalThink")
end

-- 技能升级时会调用
function modifier_witch_doctor_voodoo_restoration_lua:OnRefresh( kv )
	-- references
	self.mana_per_second = self:GetAbility():GetSpecialValueFor( "mana_per_second" )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.heal = self:GetAbility():GetSpecialValueFor( "heal" )
    self.heal_interval = self:GetAbility():GetSpecialValueFor( "heal_interval" )
	self.enemy_damage_pct = self:GetAbility():GetSpecialValueFor( "enemy_damage_pct" )/100

	if IsServer() then
		-- precache damage
		self.damageTable = {
			-- victim = target,
			attacker = caster,
			damage = self.heal * self.enemy_damage_pct,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(), --Optional.
		}

		-- Start interval
		-- 根据示例的样式写的，所以StartIntervalThink的内在逻辑应该是在调用时，注销之前的Think然后重新执行该技能的Think
		self:StartIntervalThink( self.interval_time )
		-- self:OnIntervalThink()
	end

end

function modifier_witch_doctor_voodoo_restoration_lua:OnRemoved()
end

function modifier_witch_doctor_voodoo_restoration_lua:OnDestroy()
    print("modifier_witch_doctor_voodoo_restoration_lua:OnDestroy()")
	if not IsServer() then return end
	-- Play effects
	local sound_off = "Hero_WitchDoctor.Voodoo_Restoration.Off"
	EmitSoundOn( sound_off, self:GetParent() )

    -- 移除特效
    ParticleManager:DestroyParticle(self.spell_effect,false)
	ParticleManager:ReleaseParticleIndex( self.spell_effect )
	self:StartIntervalThink( -1 )
end
--[[
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_witch_doctor_voodoo_restoration_lua:DeclareFunctions()
	local funcs = {
		-- MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,   -- = 86
        -- Method Name: `GetModifierConstantHealthRegen`
        -- MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, -- = 87
        -- Method Name: `GetModifierHealthRegenPercentage`
	}

	return funcs
end

function modifier_witch_doctor_voodoo_restoration_lua:GetModifierConstantHealthRegen( params )
    	

	return self.heal
end
]]
--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_witch_doctor_voodoo_restoration_lua:GetEffectName()
	return "particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_flame_a.vpcf"
    -- return "particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_aura.vpcf"
end

function modifier_witch_doctor_voodoo_restoration_lua:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_witch_doctor_voodoo_restoration_lua:PlayEffects(target )
	-- Get Resources
    -- 有4个子特效：witchdoctor_voodoo_restoration_b,c,d,flame_a,其中 b,c,d的效果为空，flame_a的子特效为 flame_b,flame_c,flame_d,flame_light
	-- 原版特效 witchdoctor_voodoo_restoration 会在脚底下留下一个火花特效，所以这里用 witchdoctor_voodoo_restoration_flame_a
    -- 所以是否意味着，不需要预加载子特效
	local particle_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_flame_a.vpcf"

    -- 用下面这个特效会导致十字架特效在技能关闭后不删除特效，原因可能是其粒子特效的设置不同
    -- local particle_cast = "particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_aura.vpcf"
	local sound_cast = "Hero_WitchDoctor.Voodoo_Restoration"
	local sound_loop = "Hero_WitchDoctor.Voodoo_Restoration.Loop"
	-- Create Particle
	self.spell_effect = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleAlwaysSimulate(self.spell_effect)
	ParticleManager:SetParticleControlEnt( self.spell_effect, 2, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_staff", Vector(0,0,0), true )
    -- 对于ControlPoint的意义，下面多做测试看看效果的不同？ 为什么填0后在技能结束后不能消除？
	--ParticleManager:SetParticleControl( self.spell_effect, 0, Vector(1,0,0) )
	--ParticleManager:SetParticleControl( self.spell_effect, 1, Vector(0,0,0) )
    --ParticleManager:SetParticleControl( self.spell_effect, 2, target:GetOrigin() )
    --ParticleManager:SetParticleControl( self.spell_effect, 3, target:GetOrigin() )
    --ParticleManager:SetParticleControl( self.spell_effect, 4, target:GetOrigin() )
    --ParticleManager:SetParticleControl( self.spell_effect, 5, target:GetOrigin() )
	--ParticleManager:ReleaseParticleIndex( self.spell_effect )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetParent() )
	EmitSoundOn( sound_loop, self:GetParent() )
end