modifier_witch_doctor_paralyzing_cask_lua = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_paralyzing_cask_lua:IsHidden()
	return false
end

function modifier_witch_doctor_paralyzing_cask_lua:IsDebuff()
	return true
end

function modifier_witch_doctor_paralyzing_cask_lua:IsStunDebuff()
	return false
end

function modifier_witch_doctor_paralyzing_cask_lua:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_paralyzing_cask_lua:OnCreated( kv )
	-- references
	--self.as_slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed" ) -- special value
	--self.ms_slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" ) -- special value
	self.duration = kv.duration
end

function modifier_witch_doctor_paralyzing_cask_lua:OnRefresh( kv )
	-- references
	-- self.as_slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed" ) -- special value
	-- elf.ms_slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" ) -- special value	
	self.duration = kv.duration
end

function modifier_witch_doctor_paralyzing_cask_lua:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_witch_doctor_paralyzing_cask_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}

	return funcs
end
function modifier_witch_doctor_paralyzing_cask_lua:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow
end
function modifier_witch_doctor_paralyzing_cask_lua:GetModifierAttackSpeedBonus_Constant()
	return self.as_slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_witch_doctor_paralyzing_cask_lua:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost_lich.vpcf"
end