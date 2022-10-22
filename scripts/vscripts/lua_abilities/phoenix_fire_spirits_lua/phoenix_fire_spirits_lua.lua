phoenix_fire_spirits_lua = class({})
LinkLuaModifier( "modifier_phoenix_fire_spirits_lua", "lua_abilities/phoenix_fire_spirits_lua/modifier_phoenix_fire_spirits_lua", LUA_MODIFIER_MOTION_NONE )

function phoenix_fire_spirits_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

    local buff = caster:AddNewModifier(
        caster,
        self,
        "modifier_phoenix_fire_spirits_lua",
        {
            duration = self:GetSpecialValueFor("spirit_duration"),
        }
    )
    buff:SetStackCount(self:GetSpecialValueFor("spirit_count"))
    caster:SwapAbilities("phoenix_fire_spirits_lua","phoenix_launch_fire_spirit_lua",false,true)
end

function phoenix_fire_spirits_lua:OnUpgrade()
    local sister_ability = self:GetCaster():FindAbilityByName("phoenix_launch_fire_spirit_lua")
    sister_ability:SetLevel(1)
end