phoenix_sun_ray_stop_lua = class({})

function phoenix_sun_ray_stop_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_phoenix_sun_ray_lua")

	self:OnModifierFinish()
end

function phoenix_sun_ray_stop_lua:OnModifierFinish()
    local caster = self:GetCaster()
    local brother_ability = self:GetOwner():FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
    if brother_ability then
        brother_ability:SetActivated(false)
    end
    self:GetOwner():SwapAbilities("phoenix_sun_ray_lua","phoenix_sun_ray_stop_lua",true,false)
end