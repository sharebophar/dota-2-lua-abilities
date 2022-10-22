--------------------------------------------------------------------------------
modifier_phoenix_fire_spirits_lua = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_phoenix_fire_spirits_lua:IsHidden()
	return false
end

function modifier_phoenix_fire_spirits_lua:IsDebuff()
	return true
end

function modifier_phoenix_fire_spirits_lua:IsStunDebuff()
	return true
end

function modifier_phoenix_fire_spirits_lua:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_phoenix_fire_spirits_lua:OnCreated( kv )
	-- references
	if not IsServer() then return end
	self.tick_cur_times = 1
    self.hp_cost_perc = self:GetAbility():GetSpecialValueFor("hp_cost_perc")
    self.spirit_duration = self:GetAbility():GetSpecialValueFor("spirit_duration")
    self.spirit_speed = self:GetAbility():GetSpecialValueFor("spirit_speed")
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.duration = self:GetAbility():GetSpecialValueFor("duration")
    self.attackspeed_slow = self:GetAbility():GetSpecialValueFor("attackspeed_slow")
    self.damage_per_second = self:GetAbility():GetSpecialValueFor("damage_per_second")
    self.spirit_count = self:GetAbility():GetSpecialValueFor("spirit_count")
    self.tick_interval = self:GetAbility():GetSpecialValueFor("tick_interval")
-- 创建火焰精灵环绕特效

	self:StartIntervalThink(self.tick_interval)
	self:OnIntervalThink()
end

function modifier_phoenix_fire_spirits_lua:OnRefresh( kv )
	-- self:OnCreated( kv )
	-- Refresh时，只更新配置数值
end

function modifier_phoenix_fire_spirits_lua:OnRemoved()
end

function modifier_phoenix_fire_spirits_lua:OnDestroy()
	self:StartIntervalThink(-1)
end

--------------------------------------------------------------------------------
--[[ Modifier Effects
function modifier_phoenix_fire_spirits_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
	}

	return funcs
end

function modifier_phoenix_fire_spirits_lua:GetModifierMoveSpeed_Absolute()
	if IsServer() then return self.speed end
end
]]
--------------------------------------------------------------------------------
-- Status Effects
function modifier_phoenix_fire_spirits_lua:CheckState()
	local state = {
		-- [MODIFIER_STATE_COMMAND_RESTRICTED] = true, -- 不能放技能
		--[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
		--[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_phoenix_fire_spirits_lua:GetStatusEffectName()
	-- return "particles/status_fx/particles/status_fx/status_effect_phoenix_burning.vpcf"
end

function modifier_phoenix_fire_spirits_lua:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

function modifier_phoenix_fire_spirits_lua:OnIntervalThink()

	if self.tick_cur_times <= self.spirit_duration then
		self.tick_cur_times = self.tick_cur_times + 1
	else
		self:StartIntervalThink(-1)
		self:GetParent():SwapAbilities("phoenix_fire_spirits_lua","phoenix_launch_fire_spirit_lua",true,false)
	end
end