phoenix_sun_ray_lua = class({})

LinkLuaModifier( "modifier_phoenix_sun_ray_lua", "lua_abilities/phoenix_sun_ray_lua/modifier_phoenix_sun_ray_lua", LUA_MODIFIER_MOTION_NONE )

function phoenix_sun_ray_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

    caster:AddNewModifier(
        caster,
        self,
        "modifier_phoenix_sun_ray_lua",
        {
            duration = self:GetDuration(),
        }
    )

    caster:SwapAbilities("phoenix_sun_ray_lua","phoenix_sun_ray_stop_lua",false,true)
end

function phoenix_sun_ray_lua:OnUpgrade()
    local sister_ability = self:GetCaster():FindAbilityByName("phoenix_sun_ray_stop_lua")
    sister_ability:UpgradeAbility(true)

    local brother_ability = self:GetCaster():FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
    brother_ability:UpgradeAbility(true)
    brother_ability:SetActivated(self:GetCaster():HasModifier("modifier_phoenix_sun_ray_lua"))
end
