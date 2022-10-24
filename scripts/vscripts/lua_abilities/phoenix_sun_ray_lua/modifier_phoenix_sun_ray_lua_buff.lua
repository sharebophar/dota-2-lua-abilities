modifier_phoenix_sun_ray_lua_buff = modifier_phoenix_sun_ray_lua_buff or class({})

function modifier_phoenix_sun_ray_lua_buff:IsDebuff()				return false end
function modifier_phoenix_sun_ray_lua_buff:IsHidden() 				return true end
function modifier_phoenix_sun_ray_lua_buff:IsPurgable() 				return false end
function modifier_phoenix_sun_ray_lua_buff:IsPurgeException() 		return false end
function modifier_phoenix_sun_ray_lua_buff:IsStunDebuff() 			return false end
function modifier_phoenix_sun_ray_lua_buff:RemoveOnDeath() 			return true end
function modifier_phoenix_sun_ray_lua_buff:IgnoreTenacity() 			return true end

function modifier_phoenix_sun_ray_lua_buff:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_sunray_beam_friend.vpcf" end

function modifier_phoenix_sun_ray_lua_buff:OnCreated()
	--self.tick_interval	= self:GetAbility():GetSpecialValueFor("tick_interval")
	--self.duration		= self:GetAbility():GetSpecialValueFor("duration")
	self.base_heal	= self:GetAbility():GetSpecialValueFor("base_heal")
	self.hp_perc_heal	= self:GetAbility():GetSpecialValueFor("hp_perc_heal")
    self.inc_heal_per_tick	= self:GetAbility():GetSpecialValueFor("inc_heal_per_tick")
    self.inc_heal_pct_per_tick	= self:GetAbility():GetSpecialValueFor("inc_heal_pct_per_tick")
	--self.base_damage	= self:GetAbility():GetSpecialValueFor("base_damage")

	if not IsServer() then
		return
	end
	if self:GetStackCount() < 1 then
		self:SetStackCount(1)
	end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
    local taker = self:GetParent()

	if not caster:HasModifier("modifier_phoenix_sun_ray_lua_thinker") then
		return
	end

	local num_stack = caster:FindModifierByName("modifier_phoenix_sun_ray_lua_thinker"):GetStackCount()

	local base_heal = self.base_heal
	local taker_health = taker:GetMaxHealth()
    -- 固定治疗量
	local total_heal = base_heal + taker_health * self.hp_perc_heal / 100
    -- 随时间增加的治疗量
    total_heal = total_heal + (self.inc_heal_per_tick + taker_health*self.inc_heal_pct_per_tick/100)* num_stack

    taker:Heal(total_heal,ability)
    print("治疗队友！")
end