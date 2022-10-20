phoenix_icarus_dive_stop_lua = class({})

function phoenix_icarus_dive_stop_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_phoenix_icarus_dive_lua")

	self:OnModifierFinish()
end

function phoenix_icarus_dive_stop_lua:OnModifierFinish()
	local brother_ability = self:GetOwner():FindAbilityByName("phoenix_sun_ray_lua")
	if brother_ability then
		brother_ability:SetActivated(true)
	end
	self:GetOwner():SwapAbilities("phoenix_icarus_dive_lua","phoenix_icarus_dive_stop_lua",true,false)
end