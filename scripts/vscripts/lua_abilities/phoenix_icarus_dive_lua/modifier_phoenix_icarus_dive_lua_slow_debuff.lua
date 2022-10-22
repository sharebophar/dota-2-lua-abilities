modifier_phoenix_icarus_dive_lua_slow_debuff = class({})

function modifier_phoenix_icarus_dive_lua_slow_debuff:IsDebuff()return true  end

function modifier_phoenix_icarus_dive_lua_slow_debuff:IsHidden()
	return false 
end

function modifier_phoenix_icarus_dive_lua_slow_debuff:IsPurgable() 		
	return true 
end

function modifier_phoenix_icarus_dive_lua_slow_debuff:IsPurgeException()
	return true 
end

function modifier_phoenix_icarus_dive_lua_slow_debuff:IsStunDebuff() 		return false end
function modifier_phoenix_icarus_dive_lua_slow_debuff:RemoveOnDeath() 		return true  end

function modifier_phoenix_icarus_dive_lua_slow_debuff:DeclareFunctions()
    local decFuns =
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
    return decFuns
end

function modifier_phoenix_icarus_dive_lua_slow_debuff:GetTexture()
	return "phoenix_icarus_dive"
end

function modifier_phoenix_icarus_dive_lua_slow_debuff:GetEffectName()	return "particles/units/heroes/hero_phoenix/phoenix_icarus_dive_burn_debuff.vpcf" end

function modifier_phoenix_icarus_dive_lua_slow_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_phoenix_icarus_dive_lua_slow_debuff:GetModifierMoveSpeedBonus_Percentage()	return self:GetAbility():GetSpecialValueFor("slow_movement_speed_pct") * (-1)  end
function modifier_phoenix_icarus_dive_lua_slow_debuff:OnCreated()
	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	local tick = ability:GetSpecialValueFor("burn_tick_interval")
	self:StartIntervalThink( tick )
end


function modifier_phoenix_icarus_dive_lua_slow_debuff:OnIntervalThink()
	if not IsServer() then
		return
	end
	if not self:GetParent():IsAlive() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local tick = ability:GetSpecialValueFor("burn_tick_interval")
	local dmg = ability:GetSpecialValueFor("damage_per_second") * ( tick / 1.0 )
	local damageTable = {
        victim = self:GetParent(),
        attacker = caster,
        damage = dmg,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    }
    ApplyDamage(damageTable)
end