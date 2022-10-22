phoenix_icarus_dive_lua = class({})
LinkLuaModifier( "modifier_phoenix_icarus_dive_lua", "lua_abilities/phoenix_icarus_dive_lua/modifier_phoenix_icarus_dive_lua", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_phoenix_icarus_dive_lua_slow_debuff", "lua_abilities/phoenix_icarus_dive_lua/modifier_phoenix_icarus_dive_lua_slow_debuff", LUA_MODIFIER_MOTION_NONE )
function phoenix_icarus_dive_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
    local _direction = (point - caster:GetAbsOrigin()):Normalized()
	caster:SetForwardVector(_direction)

    caster:AddNewModifier(
        caster,
        self,
        "modifier_phoenix_icarus_dive_lua",
        {
            duration = self:GetSpecialValueFor("dive_duration"),
        }
    )

    caster:SwapAbilities("phoenix_icarus_dive_lua","phoenix_icarus_dive_stop_lua",false,true)
    -- Spend HP cost
    local hp_cost_perc = self:GetSpecialValueFor("hp_cost_perc")
	self.healthCost = caster:GetHealth() * hp_cost_perc / 100
    local AfterCastHealth = caster:GetHealth() - self.healthCost
    if AfterCastHealth <= 1 then
        caster:SetHealth(1)
    else
        caster:SetHealth(AfterCastHealth)
    end

    EmitSoundOn("Hero_Phoenix.IcarusDive.Cast", caster)
end

function phoenix_icarus_dive_lua:OnUpgrade()
    local sister_ability = self:GetCaster():FindAbilityByName("phoenix_icarus_dive_stop_lua")
    sister_ability:SetLevel(1)
end