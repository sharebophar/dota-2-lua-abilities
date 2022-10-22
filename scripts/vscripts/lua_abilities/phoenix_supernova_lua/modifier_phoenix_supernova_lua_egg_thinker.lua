modifier_phoenix_supernova_lua_egg_thinker = modifier_phoenix_supernova_lua_egg_thinker or class({})

function modifier_phoenix_supernova_lua_egg_thinker:IsDebuff()					return false end
function modifier_phoenix_supernova_lua_egg_thinker:IsHidden() 				return false end
function modifier_phoenix_supernova_lua_egg_thinker:IsPurgable() 				return false end
function modifier_phoenix_supernova_lua_egg_thinker:IsPurgeException() 		return false end
function modifier_phoenix_supernova_lua_egg_thinker:IsStunDebuff() 			return false end
function modifier_phoenix_supernova_lua_egg_thinker:RemoveOnDeath() 			return true end
function modifier_phoenix_supernova_lua_egg_thinker:IgnoreTenacity() 			return true end
function modifier_phoenix_supernova_lua_egg_thinker:IsAura() 					return true end
function modifier_phoenix_supernova_lua_egg_thinker:GetAuraSearchTeam() 		return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_phoenix_supernova_lua_egg_thinker:GetAuraSearchType() 		return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO end
function modifier_phoenix_supernova_lua_egg_thinker:GetAuraRadius() 			return self:GetAbility():GetSpecialValueFor("aura_radius") end
function modifier_phoenix_supernova_lua_egg_thinker:GetModifierAura()			return "modifier_imba_phoenix_supernova_dmg" end

function modifier_phoenix_supernova_lua_egg_thinker:GetTexture() return "phoenix_supernova" end

function modifier_phoenix_supernova_lua_egg_thinker:DeclareFunctions()
    local decFuns =
    {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	    MODIFIER_EVENT_ON_ATTACKED,
        MODIFIER_EVENT_ON_DEATH,
    }
    return decFuns
end

function modifier_phoenix_supernova_lua_egg_thinker:CheckState()
	local state = 
	{
--		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
	return state
end

function modifier_phoenix_supernova_lua_egg_thinker:GetModifierIncomingDamage_Percentage()
	return -100
end

function modifier_phoenix_supernova_lua_egg_thinker:OnCreated(kv)
	if not IsServer() then
		return
	end
	local egg = self:GetParent()
	local caster = self:GetCaster()
	local pfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_phoenix/phoenix_supernova_egg.vpcf", PATTACH_ABSORIGIN_FOLLOW, egg )
	ParticleManager:SetParticleControlEnt( pfx, 1, egg, PATTACH_POINT_FOLLOW, "attach_hitloc", egg:GetAbsOrigin(), true )
	ParticleManager:ReleaseParticleIndex( pfx )
	StartSoundEvent( "Hero_Phoenix.SuperNova.Begin", egg)
	StartSoundEvent( "Hero_Phoenix.SuperNova.Cast", egg)

	local ability = self:GetAbility()
	GridNav:DestroyTreesAroundPoint(egg:GetAbsOrigin(), ability:GetSpecialValueFor("aura_radius") , false)
	self:StartIntervalThink(1)
	Timers:CreateTimer({
		endTime = kv.reborn_time, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()
		  egg:Kill(ability,egg)
		end
	  })
end

function modifier_phoenix_supernova_lua_egg_thinker:OnIntervalThink()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local egg = self:GetParent()
	if not egg:IsAlive()then
		-- 终止thinker
		return
	end
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
									egg:GetAbsOrigin(),
									nil,
									ability:GetSpecialValueFor("aura_radius"),
									DOTA_UNIT_TARGET_TEAM_ENEMY,
									DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
									DOTA_UNIT_TARGET_FLAG_NONE,
									FIND_ANY_ORDER,
									false )
	for _, enemy in pairs(enemies) do
		local damageTable = {
        victim = enemy,
        attacker = caster,
        damage = ability:GetSpecialValueFor("damage_per_sec"),
        damage_type = DAMAGE_TYPE_MAGICAL,
    	}
    	ApplyDamage(damageTable)
    end
end

function modifier_phoenix_supernova_lua_egg_thinker:OnDeath( keys )
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local egg = self:GetParent()
	local killer = keys.attacker
	if egg ~= keys.unit then
		return
	end
	if egg.IsDoubleNova then
		egg.IsDoubleNova = nil
	end
	if egg.NovaCaster then
		egg.NovaCaster = nil
	end

	caster:RemoveNoDraw()
	--[[
	if caster.ally and not caster.HasDoubleEgg then
		caster.ally:RemoveNoDraw()
	end
	]]
	egg:AddNoDraw()

	StopSoundEvent("Hero_Phoenix.SuperNova.Begin", egg)
	StopSoundEvent( "Hero_Phoenix.SuperNova.Cast", egg)
	-- 重生成功了
	if egg == killer then
		-- Phoenix reborns
		StartSoundEvent( "Hero_Phoenix.SuperNova.Explode", egg)
		local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf"
		local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_ABSORIGIN_FOLLOW, caster )
		ParticleManager:SetParticleControl( pfx, 0, egg:GetAbsOrigin() )
		ParticleManager:SetParticleControl( pfx, 1, Vector(1.5,1.5,1.5) )
		ParticleManager:SetParticleControl( pfx, 3, egg:GetAbsOrigin() )
		ParticleManager:ReleaseParticleIndex(pfx)
		self:ResetUnit(caster)
		caster:SetHealth( caster:GetMaxHealth() )
		caster:SetMana( caster:GetMaxMana() )
		-- 蓝杖的队友效果
		if caster.ally and caster.ally:IsAlive() then
			self:ResetUnit(caster.ally)
			caster.ally:SetHealth( caster.ally:GetMaxHealth() )
			caster.ally:SetMana( caster.ally:GetMaxMana() )
		end
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
									egg:GetAbsOrigin(),
									nil,
									ability:GetSpecialValueFor("aura_radius"),
									DOTA_UNIT_TARGET_TEAM_ENEMY,
									DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
									DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
									FIND_ANY_ORDER,
									false )
		for _, enemy in pairs(enemies) do
			--[[
			local item = CreateItem( "item_imba_dummy", caster, caster)
			item:ApplyDataDrivenModifier( caster, enemy, "modifier_stunned", {duration = ability:GetSpecialValueFor("stun_duration")} )
			UTIL_Remove(item)
			]]
			
			enemy:AddNewModifier(caster,ability,"modifier_generic_stunned_lua",{duration = ability:GetSpecialValueFor("stun_duration") })
    	end
	else
		-- Phoenix killed
		StartSoundEventFromPosition( "Hero_Phoenix.SuperNova.Death", egg:GetAbsOrigin())
		-- if not caster:HasTalent("special_bonus_imba_phoenix_5") then
			if caster:IsAlive() then  caster:Kill(ability, killer) end
			-- 蓝杖的逻辑
			if caster.ally and caster.ally:IsAlive() then
				caster.ally:Kill(ability, killer)
			end
		-- imba的天赋会在蛋被击碎后仍然重生
		--[[
			elseif caster:IsAlive() then
			self:ResetUnit(caster)
			caster:SetHealth( caster:GetMaxHealth() * caster:FindTalentValue("special_bonus_imba_phoenix_5","reborn_pct") / 100 )
			caster:SetMana( caster:GetMaxMana() * caster:FindTalentValue("special_bonus_imba_phoenix_5","reborn_pct") / 100)
			-- 结束隐身buff
			local egg_buff = caster:FindModifierByNameAndCaster("modifier_phoenix_supernova_lua_hide_effect", caster)
			if egg_buff then
				egg_buff:Destroy()
			end
			if caster.ally and caster.ally:IsAlive() then
				self:ResetUnit(caster.ally)
				caster.ally:SetHealth( caster.ally:GetMaxHealth() * caster:FindTalentValue("special_bonus_imba_phoenix_5","reborn_pct") / 100 )
				caster.ally:SetMana( caster.ally:GetMaxMana() * caster:FindTalentValue("special_bonus_imba_phoenix_5","reborn_pct") / 100 )
				local egg_buff2 = caster.ally:FindModifierByNameAndCaster("modifier_phoenix_supernova_lua_hide_effect", caster)
				if egg_buff2 then
					egg_buff2:Destroy()
				end
			end
			]]
		-- end
		local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_death.vpcf"
		local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_WORLDORIGIN, nil )
		local attach_point = caster:ScriptLookupAttachment( "attach_hitloc" )
		ParticleManager:SetParticleControl( pfx, 0, caster:GetAttachmentOrigin(attach_point) )
		ParticleManager:SetParticleControl( pfx, 1, caster:GetAttachmentOrigin(attach_point) )
		ParticleManager:SetParticleControl( pfx, 3, caster:GetAttachmentOrigin(attach_point) )
		ParticleManager:ReleaseParticleIndex(pfx)
	end
	FindClearSpaceForUnit(caster, egg:GetAbsOrigin(), false)
	if caster.ally then
		FindClearSpaceForUnit(caster.ally, egg:GetAbsOrigin(), false)
	end
	self.bIsFirstAttacked = nil
	caster.ally = nil
	caster.egg = nil
end

-- 冷却重置，净化所有buff/debuff
function modifier_phoenix_supernova_lua_egg_thinker:ResetUnit( unit )
	for i=0,10 do
		local abi = unit:GetAbilityByIndex(i)
		if abi then
			if abi:GetAbilityType() ~= 1 and not abi:IsItem() then
				abi:EndCooldown()
			end
		end
	end
	unit:Purge( true, true, true, true, true )
end

function modifier_phoenix_supernova_lua_egg_thinker:OnAttacked( keys )
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local egg = self:GetParent()
	local attacker = keys.attacker

	if keys.target ~= egg then
		return
	end

	if attacker:IsRealHero() then
		egg.current_attack = egg.current_attack + 1
	else
		egg.current_attack = egg.current_attack + 1 --0.25
	end
	if egg.current_attack >= egg.max_attack then
		egg:Kill(ability, attacker)
	else
		egg:SetHealth( (egg:GetMaxHealth() * ((egg.max_attack-egg.current_attack)/egg.max_attack)) )
	end
	local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_hit.vpcf"
	local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_POINT_FOLLOW, egg )
	local attach_point = egg:ScriptLookupAttachment( "attach_hitloc" )
	ParticleManager:SetParticleControlEnt( pfx, 0, egg, PATTACH_POINT_FOLLOW, "attach_hitloc", egg:GetAttachmentOrigin(attach_point), true )
	ParticleManager:SetParticleControlEnt( pfx, 1, egg, PATTACH_POINT_FOLLOW, "attach_hitloc", egg:GetAttachmentOrigin(attach_point), true )
	--ParticleManager:ReleaseParticleIndex(pfx)
end
