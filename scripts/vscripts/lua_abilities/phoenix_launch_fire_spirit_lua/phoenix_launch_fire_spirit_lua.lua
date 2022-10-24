LinkLuaModifier("modifier_phoenix_fire_spirits_lua_debuff", "lua_abilities/phoenix_fire_spirits_lua/modifier_phoenix_fire_spirits_lua_debuff", LUA_MODIFIER_MOTION_NONE)

phoenix_launch_fire_spirit_lua = class({})

function phoenix_launch_fire_spirit_lua:IsHiddenWhenStolen() 		return true end
function phoenix_launch_fire_spirit_lua:IsRefreshable() 			return true  end
function phoenix_launch_fire_spirit_lua:IsStealable() 				return false end
function phoenix_launch_fire_spirit_lua:IsNetherWardStealable() 	return false end
function phoenix_launch_fire_spirit_lua:GetAssociatedPrimaryAbilities() return "phoenix_fire_spirits_lua" end
function phoenix_launch_fire_spirit_lua:ProcsMagicStick() return false end

function phoenix_launch_fire_spirit_lua:GetAbilityTextureName()   return "phoenix_launch_fire_spirit" end

function phoenix_launch_fire_spirit_lua:GetAOERadius()  return self:GetSpecialValueFor("radius") end

--[[
function phoenix_launch_fire_spirit_lua:GetManaCost()
	if not self:GetCaster():HasTalent("special_bonus_imba_phoenix_7") then
		return 0
	else
		return self:GetCaster():FindTalentValue("special_bonus_imba_phoenix_7","mana_cost")
	end
end
]]

function phoenix_launch_fire_spirit_lua:OnSpellStart()
	if not IsServer() then
		return
	end
	local caster		= self:GetCaster()
	local point 		= self:GetCursorPosition()
	point.z = point.z + 70
	local ability		= self
	local modifierName	= "modifier_phoenix_fire_spirits_lua"
	local iModifier 	= caster:FindModifierByName(modifierName)

	caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
	EmitSoundOn("Hero_Phoenix.FireSpirits.Launch", caster)

	--if not caster:HasTalent("special_bonus_imba_phoenix_7") then
		-- Update spirits count
		local currentStack
		if iModifier then
			iModifier:DecrementStackCount()
			currentStack = iModifier:GetStackCount()
		else
			return
		end

		-- Update the particle FX
		-- 具体看看什么意思
		local pfx = caster.fire_spirits_pfx
		ParticleManager:SetParticleControl( pfx, 1, Vector( currentStack, 0, 0 ) )
		-- 为什么不直接写 for i=1,currentStak do
		for i=1, caster.fire_spirits_numSpirits do
			local radius = 0
			if i <= currentStack then
				radius = 1
			end
			-- 从modifier_generic_tracking_projectile.lua中可以知道，controlPoint从9之后都是可以随意设置的
			ParticleManager:SetParticleControl( pfx, 8+i, Vector( radius, 0, 0 ) )
		end
	--end

	-- Projectile
	local direction = (point - caster:GetAbsOrigin()):Normalized()
	local DummyUnit = CreateUnitByName("npc_dummy_unit",point,false,caster,caster:GetOwner(),caster:GetTeamNumber())
	DummyUnit:AddNewModifier(caster, ability, "modifier_kill", {duration = 0.1})
	local cast_target = DummyUnit

	local info =
		{
			Target = cast_target,
			Source = caster,
			Ability = ability,
			EffectName = "particles/hero/phoenix/phoenix_fire_spirit_launch.vpcf",
			iMoveSpeed = self:GetSpecialValueFor("spirit_speed"),
			vSourceLoc = direction,							-- Optional (HOW)
			bDrawsOnMinimap = false,						-- Optional
			bDodgeable = false,								-- Optional
			bIsAttack = false,								-- Optional
			bVisibleToEnemies = true,						-- Optional
			bReplaceExisting = false,						-- Optional
			flExpireTime = GameRules:GetGameTime() + 10,	-- Optional but recommended
			bProvidesVision = false,						-- Optional
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
		}
	ProjectileManager:CreateTrackingProjectile(info)

	-- Remove the stack modifier if all the spirits has been launched.
	if iModifier:GetStackCount() < 1 then
		iModifier:Destroy()
	end
end

function phoenix_launch_fire_spirit_lua:OnProjectileThink( vLocation )
	if not IsServer() then
		return
	end
	-- 原版在飞行的过程中应该不会造成伤害
	local caster = self:GetCaster()
	local ability = self
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
		vLocation,
		nil,
		20,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)
	for _, enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, ability, "modifier_phoenix_fire_spirits_lua_debuff", { duration = ability:GetSpecialValueFor("duration") * (1 - enemy:GetStatusResistance()) } )
	end
end

function phoenix_launch_fire_spirit_lua:OnProjectileHit( hTarget, vLocation)
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local location = vLocation
	if hTarget then
		location = hTarget:GetAbsOrigin()
	end
	-- Particles and sound
	local DummyUnit = CreateUnitByName("npc_dummy_unit",location,false,caster,caster:GetOwner(),caster:GetTeamNumber())
	DummyUnit:AddNewModifier(caster, ability, "modifier_kill", {duration = 0.1})
	local pfx_explosion = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(pfx_explosion, 0, location)
	ParticleManager:ReleaseParticleIndex(pfx_explosion)

	EmitSoundOn("Hero_Phoenix.ProjectileImpact", DummyUnit)
	EmitSoundOn("Hero_Phoenix.FireSpirits.Target", DummyUnit)

	-- Vision
	AddFOWViewer(caster:GetTeamNumber(), DummyUnit:GetAbsOrigin(), 175, 1, true)

	local units = FindUnitsInRadius(caster:GetTeamNumber(),
		location,
		nil,
		self:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)
	for _,unit in pairs(units) do
		if unit ~= caster then
			unit:AddNewModifier(caster, self, "modifier_phoenix_fire_spirits_lua_debuff", {duration = self:GetSpecialValueFor("duration") * (1 - unit:GetStatusResistance())} )
		end
	end
	return true
end

function phoenix_launch_fire_spirit_lua:GetCastAnimation()
	return ACT_DOTA_OVERRIDE_ABILITY_2
end

function phoenix_launch_fire_spirit_lua:OnUpgrade()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local this_ability = self
	local this_abilityName = self:GetAbilityName()
	local this_abilityLevel = self:GetLevel()

	-- The ability to level up
	local ability_name = "phoenix_fire_spirits_lua"
	local ability_handle = caster:FindAbilityByName(ability_name)
	local ability_level = ability_handle:GetLevel()

	-- Check to not enter a level up loop
	if ability_level ~= this_abilityLevel then
		ability_handle:SetLevel(this_abilityLevel)
	end
end