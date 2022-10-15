require("utility_functions")

modifier_witch_doctor_death_ward_lua = class({})

--[[
    -- 参考冰女的 极寒领域 学习 死亡守卫的写法
]]
--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_death_ward_lua:IsHidden()
	return true
end

function modifier_witch_doctor_death_ward_lua:IsDebuff()
	return false
end

function modifier_witch_doctor_death_ward_lua:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Aura
--[[
function modifier_witch_doctor_death_ward_lua:IsAura()
	return true
end

function modifier_witch_doctor_death_ward_lua:GetModifierAura()
	return "modifier_witch_doctor_death_ward_lua_effect"
end

function modifier_witch_doctor_death_ward_lua:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_witch_doctor_death_ward_lua:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_witch_doctor_death_ward_lua:GetAuraDuration()
	return self.slow_duration
end
]]
--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_death_ward_lua:OnCreated( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.attack_range_tooltip = self:GetAbility():GetSpecialValueFor( "attack_range_tooltip" )

    -- 蓝杖效果
	self.bounce_radius = self:GetAbility():GetSpecialValueFor( "bounce_radius" )
	self.scepter_lifesteal = self:GetAbility():GetSpecialValueFor( "scepter_lifesteal" )
	self.bonus_accuracy = self:GetAbility():GetSpecialValueFor( "bonus_accuracy" )
    print("On Ward Created! 不明白为什么OnCreated会执行两次？kv：",kv)
    PrintTable(kv)
    -- 所以这里防止重复创建，第二次重复创建时，kv的数据不一样，还会出现奇奇怪怪的报错，说很多接口不存在
    -- 得查一下是不是所有的引导技能添加的修改器 都会执行两次OnCreate ?
    --[[
        OnSpellStart:
        On Ward Created! 不明白为什么OnCreated会执行两次？kv：	table: 0x03f698d0
        creationtime:70.765930175781
        duration:8
        createOnSpellStart:1
        position is:	Vector 0000000003F69FF0 [-1648.962402 173.399841 128.000000]
        OnSpellStart Executed:
        On Ward Created! 不明白为什么OnCreated会执行两次？kv：	table: 0x03c9f380
        auraOwner:0
        duration:8
        stack_count:0
        creationtime:70.765930175781
        isProvidedByAura:0
    ]]
    if not IsServer() then return end
    if kv.createOnSpellStart then
        self:CreateWard()
        self.death_ward:SetBaseDamageMin(self.damage)
        self.death_ward:SetBaseDamageMax(self.damage)
    end
end

function modifier_witch_doctor_death_ward_lua:OnRefresh( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.attack_range_tooltip = self:GetAbility():GetSpecialValueFor( "attack_range_tooltip" )

    -- 蓝杖效果
	self.bounce_radius = self:GetAbility():GetSpecialValueFor( "bounce_radius" )
	self.scepter_lifesteal = self:GetAbility():GetSpecialValueFor( "scepter_lifesteal" )
	self.bonus_accuracy = self:GetAbility():GetSpecialValueFor( "bonus_accuracy" )

end

function modifier_witch_doctor_death_ward_lua:OnDestroy( kv )
    self:DestroyWard()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_witch_doctor_death_ward_lua:OnIntervalThink()
	
end

-- 创建死亡守卫
function modifier_witch_doctor_death_ward_lua:CreateWard()
    local caster = self:GetCaster()
    -- 不明白为什么这里提示GetCursorPosition()函数不存在？attempt to call method 'GetCursorPosition' (a nil value)
    -- 因为OnCreate不知什么原因调用了两次导致的
    local position = self:GetAbility():GetCursorPosition()
    -- local position = Vector(kv.position_x,kv.position_y,kv.position_z)
    -- print("position is:",position)
    -- Creates the death ward (There is no way to control the default ward, so this is a custom one)
    self.death_ward = CreateUnitByName("npc_dota_witch_doctor_death_ward_lua", position, true, caster, caster, caster:GetTeamNumber())
    self.death_ward:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    self.death_ward:SetOwner(caster)

    -- Applies the modifier (gives it damage, removes health bar, and makes it invulnerable)
    -- CDOTA_Ability_DataDriven extends CDOTABaseAbility 数据驱动的技能才能使用数据驱动的修改器，所以这里我添加自己定义的修改器
    -- ability:ApplyDataDrivenModifier(caster, caster.death_ward, "modifier_death_ward_datadriven", {})

    -- 为死亡守卫添加修改器
    self.death_ward:AddNewModifier(
        caster,
        self:GetAbility(),
        --nil,
        "modifier_witch_doctor_death_ward_lua_effect",
        {
            attack_range = self.attack_range_tooltip,
        } -- kv
    )

    -- 死亡守卫每隔一段时间要找最近的单位攻击，死亡守卫的攻击特效是由死亡守卫自身决定的。

    -- 死亡守卫的所有效果会在修改器移除时移除
    -- 创建光晕效果
    local ward_glow_effect = "particles/units/heroes/hero_witchdoctor/witchdoctor_deathward_glow_c.vpcf"
    ParticleManager:CreateParticle(ward_glow_effect, PATTACH_CUSTOMORIGIN, self.death_ward)
    -- 创建死亡守卫的周身特效
    local around_effect = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_skull.vpcf"
    local cast_around_effect = ParticleManager:CreateParticle(around_effect, PATTACH_CUSTOMORIGIN, self.death_ward)
    ParticleManager:SetParticleControlEnt(
        cast_around_effect,
        0,
        self.death_ward,
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        self.death_ward:GetAbsOrigin(),
        true
    )
    -- 创建权杖特效
    local stuff_effect = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_cast_staff_fire.vpcf"
    self.cast_stuff = ParticleManager:CreateParticle(stuff_effect, PATTACH_CUSTOMORIGIN, caster)
end

--[[Author: YOLOSPAGHETTI
    Date: March 15, 2016
    Removes the death ward entity from the game and stops its sound]]
function modifier_witch_doctor_death_ward_lua:DestroyWard(keys)
    local caster = self:GetCaster()
    UTIL_Remove(self.death_ward) -- 移除指定对象，不走死亡逻辑
    self.death_ward = nil

    local ward_attack_sound = "Hero_WitchDoctor_Ward.Attack"
    StopSoundEvent(ward_attack_sound, caster)
    if self.cast_stuff then
        ParticleManager:DestroyParticle(self.cast_stuff, false)
        ParticleManager:ReleaseParticleIndex(self.cast_stuff)
        self.cast_stuff = nil
    end
end
    