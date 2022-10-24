phoenix_fire_spirits_lua = class({})
LinkLuaModifier( "modifier_phoenix_fire_spirits_lua", "lua_abilities/phoenix_fire_spirits_lua/modifier_phoenix_fire_spirits_lua", LUA_MODIFIER_MOTION_NONE )

function phoenix_fire_spirits_lua:IsHiddenWhenStolen() 	return false end
function phoenix_fire_spirits_lua:IsRefreshable() 			return true  end
function phoenix_fire_spirits_lua:IsStealable() 			return true  end
function phoenix_fire_spirits_lua:IsNetherWardStealable() 	return false end
function phoenix_fire_spirits_lua:GetAssociatedSecondaryAbilities() return "phoenix_launch_fire_spirit_lua" end

function phoenix_fire_spirits_lua:GetAbilityTextureName() return "phoenix_fire_spirits" end

function phoenix_fire_spirits_lua:OnSpellStart()
	if not IsServer() then
		return
	end

	local caster	= self:GetCaster()
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
	EmitSoundOn("Hero_Phoenix.FireSpirits.Cast", caster)

	caster.ability_spirits = self

	local hpCost		= self:GetSpecialValueFor("hp_cost_perc")
	local numSpirits	= self:GetSpecialValueFor("spirit_count")
	local AfterCastHealth = caster:GetHealth()-(caster:GetHealth() * hpCost / 100)

    if AfterCastHealth <= 1 then
        caster:SetHealth(1)
    else
        caster:SetHealth(AfterCastHealth)
    end

	-- Create particle FX
	local particleName = "particles/units/heroes/hero_phoenix/phoenix_fire_spirits.vpcf"
	local pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( pfx, 1, Vector( numSpirits, 0, 0 ) )
	for i=1, numSpirits do
		ParticleManager:SetParticleControl( pfx, 8+i, Vector( 1, 0, 0 ) )
	end

	caster.fire_spirits_numSpirits	= numSpirits
	caster.fire_spirits_pfx			= pfx

	-- Set the stack count
	local iDuration = self:GetSpecialValueFor("spirit_duration")
    --[[
	if self:GetCaster():HasTalent("special_bonus_imba_phoenix_7") then
		iDuration = iDuration * self:GetCaster():FindTalentValue("special_bonus_imba_phoenix_7","duration_pct") / 100
	end
    ]]
	caster:AddNewModifier(caster, self, "modifier_phoenix_fire_spirits_lua", { duration =  iDuration})
	caster:SetModifierStackCount( "modifier_phoenix_fire_spirits_lua", caster, numSpirits )

	-- Swap sub ability
	local sub_ability_name	= self:GetAssociatedSecondaryAbilities()
	local main_ability_name	= self:GetAbilityName()
	caster:SwapAbilities( main_ability_name, sub_ability_name, false, true )
end

function phoenix_fire_spirits_lua:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

function phoenix_fire_spirits_lua:OnUpgrade()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local this_ability = self
	local this_abilityName = self:GetAbilityName()
	local this_abilityLevel = self:GetLevel()

	-- The ability to level up
	local ability_name = "phoenix_launch_fire_spirit_lua"
	local ability_handle = caster:FindAbilityByName(ability_name)
	if ability_handle then
		local ability_level = ability_handle:GetLevel()

		-- Check to not enter a level up loop
		if ability_level ~= this_abilityLevel then
			ability_handle:SetLevel(this_abilityLevel)
		end
	end
end