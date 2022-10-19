phoenix_icarus_dive_lua = class({})
LinkLuaModifier( "modifier_phoenix_icarus_dive_lua", "lua_abilities/phoenix_icarus_dive_lua/modifier_phoenix_icarus_dive_lua", LUA_MODIFIER_MOTION_NONE )

function phoenix_icarus_dive_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

    caster:AddNewModifier(
        caster,
        self,
        "modifier_phoenix_icarus_dive_lua",
        {
            duration = self:GetSpecialValueFor("dive_duration"),
        }
    )

    caster:SwapAbilities("phoenix_icarus_dive_lua","phoenix_icarus_dive_stop_lua",false,true)
end

function phoenix_icarus_dive_lua:OnUpgrade()
    local sister_ability = self:GetCaster():FindAbilityByName("phoenix_icarus_dive_stop_lua")
    sister_ability:UpgradeAbility(true)
end