modifier_phoenix_supernova_lua_hide_effect = class({})

function modifier_phoenix_supernova_lua_hide_effect:IsDebuff()				return false end
function modifier_phoenix_supernova_lua_hide_effect:IsHidden() 				return false end
function modifier_phoenix_supernova_lua_hide_effect:IsPurgable() 				return false end
function modifier_phoenix_supernova_lua_hide_effect:IsPurgeException() 		return false end
function modifier_phoenix_supernova_lua_hide_effect:IsStunDebuff() 			return false end
function modifier_phoenix_supernova_lua_hide_effect:RemoveOnDeath() 			return true end
function modifier_phoenix_supernova_lua_hide_effect:IgnoreTenacity() 			return true end

function modifier_phoenix_supernova_lua_hide_effect:GetTexture() return "phoenix_supernova" end

function modifier_phoenix_supernova_lua_hide_effect:DeclareFunctions()
    local decFuns =
    {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        -- MODIFIER_EVENT_ON_DEATH,
    }
    return decFuns
end

function modifier_phoenix_supernova_lua_hide_effect:CheckState()
	local state = 
	{
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_DISARMED] = true,
		--[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
		--[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
	}
	return state
end

function modifier_phoenix_supernova_lua_hide_effect:GetModifierIncomingDamage_Percentage()
	return -100
end

function modifier_phoenix_supernova_lua_hide_effect:OnCreated(kv)
	if not IsServer() then
		return 
	end
    --[[
	if self:GetAbility():IsStolen() then
		return
	end
	local caster = self:GetCaster()
	local abi = caster:FindAbilityByName("imba_phoenix_launch_fire_spirit")
	if abi then
		if self:GetParent() == self:GetCaster() and abi:IsTrained() then
			self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_phoenix_supernova_bird_thinker", {duration = self:GetDuration()}) 
		end
	end
	local innate = caster:FindAbilityByName("imba_phoenix_burning_wings")
	if innate then
		if innate:GetToggleState() then
			innate:ToggleAbility()
		end
	end
    ]]
    self:GetParent():AddNoDraw()
end

--[[
function modifier_phoenix_supernova_lua_hide_effect:OnDeath( keys )
	if not IsServer() then
		return
	end
	if keys.unit == self:GetParent() then
		if keys.unit ~= self:GetCaster() then
			local caster = self:GetCaster()
			caster.ally = nil
		end
		local eggs = FindUnitsInRadius(self:GetParent():GetTeamNumber(),
									self:GetParent():GetAbsOrigin(),
									nil,
									2500,
									DOTA_UNIT_TARGET_TEAM_BOTH,
									DOTA_UNIT_TARGET_ALL,
									DOTA_UNIT_TARGET_FLAG_NONE,
									FIND_ANY_ORDER,
									false )
		for _, egg in pairs(eggs) do
			if egg:GetUnitName() == "npc_dota_phoenix_sun" and egg:GetTeamNumber() == self:GetParent():GetTeamNumber() and egg:GetOwner() == self:GetParent():GetOwner() then
				egg:Kill(self:GetAbility(), keys.attacker)
			end
		end
	end
end
]]

function modifier_phoenix_supernova_lua_hide_effect:OnDestroy()
	if not IsServer() then
		return
	end
	if self:GetCaster():GetUnitName() == "npc_dota_hero_pangtong" or self:GetCaster():GetUnitName() == "npc_dota_hero_phoenix" then
		self:GetCaster():StartGesture(ACT_DOTA_INTRO)
	end
    local owner = self:GetParent()
    if owner:IsAlive() then
        -- UTIL_Remove(caster.egg)
        owner:RemoveNoDraw()
    end
end