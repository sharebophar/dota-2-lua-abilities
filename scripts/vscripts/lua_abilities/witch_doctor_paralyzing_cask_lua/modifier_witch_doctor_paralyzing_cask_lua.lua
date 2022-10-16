modifier_witch_doctor_paralyzing_cask_lua = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_paralyzing_cask_lua:IsDebuff()
	return true
end

function modifier_witch_doctor_paralyzing_cask_lua:IsStunDebuff()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_paralyzing_cask_lua:OnCreated( kv )
	if not IsServer() then return end
	
	self.particle = "particles/generic_gameplay/generic_stunned.vpcf"
	if kv.bash==1 then
		self.particle = "particles/generic_gameplay/generic_bashed.vpcf"
	end


	-- calculate status resistance
	local resist = 1-self:GetParent():GetStatusResistance()
	local duration = kv.duration*resist
	self:SetDuration( duration, true )

	-- 播放特效
	self.stun_effect = ParticleManager:CreateParticle(self.particle, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
end

function modifier_witch_doctor_paralyzing_cask_lua:OnRefresh( kv )
	if self.stun_effect then
		ParticleManager:DestroyParticle(self.stun_effect,true)
		ParticleManager:ReleaseParticleIndex(self.stun_effect)
	end
	self:OnCreated( kv )
end

function modifier_witch_doctor_paralyzing_cask_lua:OnRemoved()
	
end

function modifier_witch_doctor_paralyzing_cask_lua:OnDestroy()
	if self.stun_effect then
		ParticleManager:DestroyParticle(self.stun_effect,false)
		ParticleManager:ReleaseParticleIndex(self.stun_effect)
	end
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_witch_doctor_paralyzing_cask_lua:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_witch_doctor_paralyzing_cask_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}

	return funcs
end

function modifier_witch_doctor_paralyzing_cask_lua:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_witch_doctor_paralyzing_cask_lua:GetEffectName()
	return self.particle
end

function modifier_witch_doctor_paralyzing_cask_lua:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end