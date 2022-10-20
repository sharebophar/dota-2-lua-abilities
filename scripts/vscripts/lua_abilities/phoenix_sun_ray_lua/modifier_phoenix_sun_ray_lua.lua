-- Created by Elfansoer
--[[
-- 参考紫猫的残阴 aether_remnant，写强制路径移动技能
]]
--------------------------------------------------------------------------------
modifier_phoenix_sun_ray_lua = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_phoenix_sun_ray_lua:IsHidden()
	return false
end

function modifier_phoenix_sun_ray_lua:IsDebuff()
	return true
end

function modifier_phoenix_sun_ray_lua:IsStunDebuff()
	return true
end

function modifier_phoenix_sun_ray_lua:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_phoenix_sun_ray_lua:OnCreated( kv )
	-- references
	if not IsServer() then return end
    self.caster = self:GetCaster()
	self.hp_cost_perc_per_second = self:GetAbility():GetSpecialValueFor("hp_cost_perc_per_second")
	self.base_damage = self:GetAbility():GetSpecialValueFor("base_damage")
	self.hp_perc_damage = self:GetAbility():GetSpecialValueFor("hp_perc_damage")
	self.base_heal = self:GetAbility():GetSpecialValueFor("base_heal")
	self.hp_perc_heal = self:GetAbility():GetSpecialValueFor("hp_perc_heal")
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.tick_interval = self:GetAbility():GetSpecialValueFor("tick_interval")
	self.forward_move_speed = self:GetAbility():GetSpecialValueFor("forward_move_speed")
	self.turn_rate_initial = self:GetAbility():GetSpecialValueFor("turn_rate_initial")
    self.turn_rate = self:GetAbility():GetSpecialValueFor("turn_rate")
    self.shard_move_slow_pct = self:GetAbility():GetSpecialValueFor("shard_move_slow_pct")

	self.tick_cur_times = 1
	self.tick_reset_times = 1/self.tick_interval -- 每秒跳多少次
    self.tick_total_times = self.tick_reset_times * self:GetDuration()

	self:StartIntervalThink(self.tick_interval)
	self:OnIntervalThink()

    local brother_ability = self.caster:FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
    brother_ability:SetActivated(true)
end

function modifier_phoenix_sun_ray_lua:OnRefresh( kv )
	-- self:OnCreated( kv )
	-- Refresh时，只更新配置数值
end

function modifier_phoenix_sun_ray_lua:OnRemoved()
    
end

function modifier_phoenix_sun_ray_lua:OnDestroy()
	self:StartIntervalThink(-1)
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_phoenix_sun_ray_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
	}

	return funcs
end

function modifier_phoenix_sun_ray_lua:GetModifierMoveSpeed_Absolute()
	if IsServer() then return self.speed end
end
--------------------------------------------------------------------------------
-- Status Effects
function modifier_phoenix_sun_ray_lua:CheckState()
	local state = {
		-- [MODIFIER_STATE_COMMAND_RESTRICTED] = true, -- 不能放技能
		[MODIFIER_STATE_ROOTED] = self:GetToggleMoveState(), -- 如何把头顶的缠绕显示进度条移除？
        [MODIFIER_STATE_DISARMED] = true, -- 不能攻击，要与不能移动分开
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_ALLOW_PATHING_THROUGH_FISSURE] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_phoenix_sun_ray_lua:GetStatusEffectName()
	-- return "particles/status_fx/status_effect_void_spirit_aether_remnant.vpcf"
end

function modifier_phoenix_sun_ray_lua:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

function modifier_phoenix_sun_ray_lua:OnIntervalThink()

	if self.tick_cur_times <= self.tick_total_times then
		self.tick_cur_times = self.tick_cur_times + 1
	else
		self:StartIntervalThink(-1)
        self:OnModifierFinish()
	end
end


-- 自定义函数
function modifier_phoenix_sun_ray_lua:GetToggleMoveState()
    local brother_ability = self:GetCaster():FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
    -- local isActived = brother_ability:IsActivated()
    local isToggled = brother_ability:IsToggleMove()
    local isDiving = self:GetCaster():HasModifier("modifier_phoenix_icarus_dive_lua")
    -- print("isActived:"..tostring(isActived).."isToggled:"..tostring(isToggled))
    return not isDiving and not isToggled
end

function modifier_phoenix_sun_ray_lua:OnModifierFinish()
    local brother_ability = self:GetParent():FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
    brother_ability:SetActivated(false)
    brother_ability:ResetToggleMove()
    self:GetParent():SwapAbilities("phoenix_sun_ray_lua","phoenix_sun_ray_stop_lua",true,false)
end