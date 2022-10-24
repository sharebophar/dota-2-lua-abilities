--------------------------------------------------------------------------------
modifier_phoenix_fire_spirits_lua = class({})

--------------------------------------------------------------------------------
function modifier_phoenix_fire_spirits_lua:IsDebuff()			return false end
function modifier_phoenix_fire_spirits_lua:IsHidden() 			return false end
function modifier_phoenix_fire_spirits_lua:IsPurgable() 			return false end
function modifier_phoenix_fire_spirits_lua:IsPurgeException() 	return false end
function modifier_phoenix_fire_spirits_lua:IsStunDebuff() 		return false end
function modifier_phoenix_fire_spirits_lua:RemoveOnDeath() 		return true  end

function modifier_phoenix_fire_spirits_lua:GetTexture()
	return "phoenix_fire_spirits"
end

function modifier_phoenix_fire_spirits_lua:OnCreated()
	if not IsServer() then
		return
	end
	self:StartIntervalThink(1.0)
end

function modifier_phoenix_fire_spirits_lua:OnIntervalThink()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("phoenix_launch_fire_spirit_lua")
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		192,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)
	-- 斧王岛最新测试发现靠近不会造成伤害了
	for _, enemy in pairs(enemies) do
		-- enemy:AddNewModifier(caster, ability, "modifier_phoenix_fire_spirits_lua_debuff", { duration = ability:GetSpecialValueFor("duration") * (1 - enemy:GetStatusResistance()) } )
	end
end

function modifier_phoenix_fire_spirits_lua:OnDestroy()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local pfx = caster.fire_spirits_pfx
	if pfx then
		ParticleManager:DestroyParticle( pfx, false )
		ParticleManager:ReleaseParticleIndex( pfx )
	end
	local main_ability_name	= "phoenix_fire_spirits_lua"
	local sub_ability_name	= "phoenix_launch_fire_spirit_lua"
	if caster then
		caster:SwapAbilities( main_ability_name, sub_ability_name, true, false )
	end
end