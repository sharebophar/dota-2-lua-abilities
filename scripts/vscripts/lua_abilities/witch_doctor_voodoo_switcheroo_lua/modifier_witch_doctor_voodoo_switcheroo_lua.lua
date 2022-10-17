require("utility_functions")

modifier_witch_doctor_voodoo_switcheroo_lua = class({})

--[[
    -- 参考仙女龙的相位转移和巫医的死亡守卫的写法
]]
--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_voodoo_switcheroo_lua:IsHidden()
	return true
end

function modifier_witch_doctor_voodoo_switcheroo_lua:IsDebuff()
	return false
end

function modifier_witch_doctor_voodoo_switcheroo_lua:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Aura
--[[
function modifier_witch_doctor_voodoo_switcheroo_lua:IsAura()
	return true
end

function modifier_witch_doctor_voodoo_switcheroo_lua:GetModifierAura()
	return "modifier_witch_doctor_voodoo_switcheroo_lua_effect"
end

function modifier_witch_doctor_voodoo_switcheroo_lua:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_witch_doctor_voodoo_switcheroo_lua:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_witch_doctor_voodoo_switcheroo_lua:GetAuraDuration()
	return self.slow_duration
end
]]
--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_voodoo_switcheroo_lua:OnCreated( kv )
	-- references
	self.attack_speed_reduction = self:GetAbility():GetSpecialValueFor( "attack_speed_reduction" )
    -- 蓝杖效果

    -- 这几个值，巫毒变身术并没有提供，该如何获取？先单独配置吧，官方肯定有获得相关技能（死亡守卫）的参数配置的方法
	self.bounce_radius = self:GetAbility():GetSpecialValueFor( "bounce_radius" )
	self.scepter_lifesteal = self:GetAbility():GetSpecialValueFor( "scepter_lifesteal" )
	self.bonus_accuracy = self:GetAbility():GetSpecialValueFor( "bonus_accuracy" )

    print("+++++++++++++ On Shard Ward Created! kv：",kv)
    PrintTable(kv)
    if not IsServer() then return end

	self:GetParent():AddNoDraw()
    if kv.createOnSpellStart then
        -- 延迟一小段时间(下一帧)创建，防止碰撞导致的偏移
        self:GetParent():SetContextThink( "CreateWard", function() 
            self:CreateWard()
        end, 0 )
    end
end

function modifier_witch_doctor_voodoo_switcheroo_lua:OnRefresh( kv )
	-- references
	self.attack_speed_reduction = self:GetAbility():GetSpecialValueFor( "attack_speed_reduction" )
end

function modifier_witch_doctor_voodoo_switcheroo_lua:OnDestroy( kv )
    self:GetParent():RemoveNoDraw()
    self:DestroyWard()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_witch_doctor_voodoo_switcheroo_lua:OnIntervalThink()
	
end

-- 创建死亡守卫
function modifier_witch_doctor_voodoo_switcheroo_lua:CreateWard()
    local caster = self:GetCaster()
    local position = caster:GetOrigin()
    self.death_ward = CreateUnitByName("npc_dota_witch_doctor_death_ward_lua", position, true, caster, caster, caster:GetTeamNumber())
    self.death_ward:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    self.death_ward:SetOwner(caster)
    -- 为死亡守卫添加修改器
    self.death_ward:AddNewModifier(
        caster,
        self:GetAbility(),
        "modifier_witch_doctor_death_ward_lua_effect",
        {
            attack_range = self.death_ward:GetAcquisitionRange(),
            delay = 0.22, -- 攻击间隔
        } -- kv
    )

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
end

-- 移除死亡守卫
function modifier_witch_doctor_voodoo_switcheroo_lua:DestroyWard(keys)
    local caster = self:GetCaster()
    UTIL_Remove(self.death_ward) -- 移除指定对象，不走死亡逻辑
    self.death_ward = nil

    local ward_attack_sound = "Hero_WitchDoctor_Ward.Attack"
    StopSoundEvent(ward_attack_sound, caster)
end

-- Status Effects
function modifier_witch_doctor_voodoo_switcheroo_lua:CheckState()
	local state = {
		[MODIFIER_STATE_INVULNERABLE] = true, -- 无敌的
        -- [MODIFIER_STATE_NO_HEALTH_BAR] = true, -- 不显示血条的
        -- [MODIFIER_STATE_UNSELECTABLE] = true, -- 不可被选中的
        -- [MODIFIER_STATE_UNTARGETABLE] = true, -- 不能作为目标的
        [MODIFIER_STATE_STUNNED] = true, -- 不能移动和攻击，但是可以点击目标
        -- [MODIFIER_STATE_ROOTED] = true, -- 
        -- 这个点击地面移动或攻击目标提示无法行动，官方是无法移动；但可以做到不会把移动指令放入操作队列
        [MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,  -- 没有找到仅忽略移动指定的状态枚举，就用这个代替了
        -- [MODIFIER_STATE_DISARMED] = true, -- 缴械，发现生物基类的情况下会对目标普攻
        -- [MODIFIER_STATE_BLOCK_DISABLED] = true, -- 无视碰撞？
        [MODIFIER_STATE_OUT_OF_GAME] = true, -- 放逐，不受游戏中的仇恨单位影响
        -- [MODIFIER_STATE_INVISIBLE] = true, -- 隐身
        -- [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true, -- 真实视野免疫，撒粉无效
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true, -- 没有单位碰撞
        -- [MODIFIER_STATE_NOT_ON_MINIMAP] = true,	   -- 不在小地图上显示，包括友方也看不见
	}

	return state
end

--[[
-- Modifier Effects
function modifier_witch_doctor_voodoo_switcheroo_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,  -- 这是隐身，并不是隐藏模型
	}

	return funcs
end

function modifier_witch_doctor_voodoo_switcheroo_lua:GetModifierInvisibilityLevel()
	return 2
end
]]
    