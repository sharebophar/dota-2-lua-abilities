modifier_phoenix_sun_ray_lua_debuff = modifier_phoenix_sun_ray_lua_debuff or class({})

function modifier_phoenix_sun_ray_lua_debuff:IsDebuff()				return true end
function modifier_phoenix_sun_ray_lua_debuff:IsHidden() 				return true end
function modifier_phoenix_sun_ray_lua_debuff:IsPurgable() 				return false end
function modifier_phoenix_sun_ray_lua_debuff:IsPurgeException() 		return false end
function modifier_phoenix_sun_ray_lua_debuff:IsStunDebuff() 			return false end
function modifier_phoenix_sun_ray_lua_debuff:RemoveOnDeath() 			return true end
function modifier_phoenix_sun_ray_lua_debuff:IgnoreTenacity() 			return true end

function modifier_phoenix_sun_ray_lua_debuff:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_sunray_debuff.vpcf" end

function modifier_phoenix_sun_ray_lua_debuff:OnCreated()
	--self.tick_interval	= self:GetAbility():GetSpecialValueFor("tick_interval")
	--self.duration		= self:GetAbility():GetSpecialValueFor("duration")
	self.base_damage	= self:GetAbility():GetSpecialValueFor("base_damage")
	self.hp_perc_damage	= self:GetAbility():GetSpecialValueFor("hp_perc_damage")
    self.inc_dmg_per_tick	= self:GetAbility():GetSpecialValueFor("inc_dmg_per_tick")
    self.inc_dmg_pct_per_tick	= self:GetAbility():GetSpecialValueFor("inc_dmg_pct_per_tick")
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

	local base_dmg = self.base_damage
	local taker_health = taker:GetMaxHealth()
    -- 固定伤害
	local total_damage = base_dmg + taker_health * self.hp_perc_damage / 100
    -- 随时间增加的伤害
    total_damage = total_damage + (self.inc_dmg_per_tick + taker_health*self.inc_dmg_pct_per_tick/100)* num_stack
	local damageTable = {
		victim = taker,
		attacker = caster,
		damage = total_damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	}
	ApplyDamage(damageTable)
end