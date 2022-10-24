modifier_phoenix_fire_spirits_lua_debuff = class({})

function modifier_phoenix_fire_spirits_lua_debuff:IsDebuff()			return true  end
function modifier_phoenix_fire_spirits_lua_debuff:IsHidden() 			return false end
function modifier_phoenix_fire_spirits_lua_debuff:IsPurgable() 		return true  end
function modifier_phoenix_fire_spirits_lua_debuff:IsPurgeException() 	return true  end
function modifier_phoenix_fire_spirits_lua_debuff:IsStunDebuff() 		return false end
function modifier_phoenix_fire_spirits_lua_debuff:RemoveOnDeath() 		return true  end

function modifier_phoenix_fire_spirits_lua_debuff:DeclareFunctions()
	local decFuns =
		{
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
		}
	return decFuns
end

function modifier_phoenix_fire_spirits_lua_debuff:GetTexture()
	return "phoenix_fire_spirits"
end

function modifier_phoenix_fire_spirits_lua_debuff:OnCreated()
	self.attackspeed_slow	= self:GetAbility():GetSpecialValueFor("attackspeed_slow") * (-1)

	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	if self:GetStackCount() <= 1 then
		self:SetStackCount(1)
	end
	
	self.tick_interval		= self:GetAbility():GetSpecialValueFor("tick_interval")
	self.damage_per_second	= self:GetAbility():GetSpecialValueFor("damage_per_second")
	
	self:StartIntervalThink( self.tick_interval )
end

function modifier_phoenix_fire_spirits_lua_debuff:OnRefresh()
	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	if self:GetStackCount() <= 1 then
		self:SetStackCount(1)
	end
end

function modifier_phoenix_fire_spirits_lua_debuff:OnIntervalThink()
	if not IsServer() then
		return
	end
	
	if not self:GetParent():IsAlive() then
		return
	end
	
	local damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = (self.damage_per_second * ( self.tick_interval / 1.0 )) * self:GetStackCount(),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(),
	}
	ApplyDamage(damageTable)
end

function modifier_phoenix_fire_spirits_lua_debuff:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn.vpcf" end
function modifier_phoenix_fire_spirits_lua_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_phoenix_fire_spirits_lua_debuff:GetModifierAttackSpeedBonus_Constant()
	if self:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
		return 0
	else
		return self:GetStackCount() * self.attackspeed_slow
	end
end