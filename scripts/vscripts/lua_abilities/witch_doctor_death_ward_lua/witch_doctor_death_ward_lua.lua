witch_doctor_death_ward_lua = class({})
LinkLuaModifier( "modifier_witch_doctor_death_ward_lua", "lua_abilities/witch_doctor_death_ward_lua/modifier_witch_doctor_death_ward_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_witch_doctor_death_ward_lua_effect", "lua_abilities/witch_doctor_death_ward_lua/modifier_witch_doctor_death_ward_lua_effect", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function witch_doctor_death_ward_lua:OnSpellStart()
    print("OnSpellStart:")
	-- unit identifier
	local caster = self:GetCaster()
    local position = self:GetCursorPosition()
	-- Add modifier
	self.modifier = caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_witch_doctor_death_ward_lua", -- modifier name
		{   duration = self:GetChannelTime(),
            createOnSpellStart = true,
        } -- kv
	)
    print("OnSpellStart Executed:")
end

--------------------------------------------------------------------------------
-- Ability Channeling
-- function witch_doctor_death_ward_lua:GetChannelTime()

-- end

function witch_doctor_death_ward_lua:OnChannelFinish( bInterrupted )
	if self.modifier then
		self.modifier:Destroy()
		self.modifier = nil
	end
end

--------------------------------------------------------------------------------
-- Ability Considerations
function witch_doctor_death_ward_lua:AbilityConsiderations()
	-- Scepter
	local bScepter = caster:HasScepter()

	-- Linken & Lotus
	local bBlocked = target:TriggerSpellAbsorb( self )

	-- Break
	local bBroken = caster:PassivesDisabled()

	-- Advanced Status
	local bInvulnerable = target:IsInvulnerable()
	local bInvisible = target:IsInvisible()
	local bHexed = target:IsHexed()
	local bMagicImmune = target:IsMagicImmune()

	-- Illusion Copy
	local bIllusion = target:IsIllusion()
end