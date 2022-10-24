modifier_phoenix_sun_ray_lua = class({})

function modifier_phoenix_sun_ray_lua:IsDebuff()			return false end
function modifier_phoenix_sun_ray_lua:IsHidden() 			return false  end
function modifier_phoenix_sun_ray_lua:IsPurgable() 		return false end
function modifier_phoenix_sun_ray_lua:IsPurgeException() 	return false end
function modifier_phoenix_sun_ray_lua:IsStunDebuff() 		return false end
function modifier_phoenix_sun_ray_lua:RemoveOnDeath() 	return true  end

function modifier_phoenix_sun_ray_lua:DeclareFunctions()
	local funcs = { 
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_MAX,
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE
	}
	return funcs
end

function modifier_phoenix_sun_ray_lua:CheckState()
	return  { 
		-- 用ROOTED会导致头顶有缠绕进度条，所以应该用 MODIFIER_PROPERTY_MOVESPEED_MAX 和 MODIFIER_PROPERTY_MOVESPEED_LIMIT
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
	}
end

function modifier_phoenix_sun_ray_lua:GetModifierMoveSpeed_Limit()
	return 1
end

function modifier_phoenix_sun_ray_lua:GetModifierMoveSpeed_Max()
	if self:GetToggleMoveState() then
		return 1
	else
		return
	end
end

function modifier_phoenix_sun_ray_lua:GetModifierIgnoreCastAngle()
	return 360
end

function modifier_phoenix_sun_ray_lua:GetEffectName()
	return "particles/units/heroes/hero_phoenix/phoenix_sunray_mane.vpcf"
end

function modifier_phoenix_sun_ray_lua:OnCreated()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	self.hp_cost_perc_per_second = self:GetAbility():GetSpecialValueFor("hp_cost_perc_per_second")
	self.tick_interval = self:GetAbility():GetSpecialValueFor("tick_interval")
	
	caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_3)
	StartSoundEvent("Hero_Phoenix.SunRay.Loop", caster)
	
	local particleName = "particles/units/heroes/hero_phoenix/phoenix_sunray_flare.vpcf"
	self.pfx_sunray_flare = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt( self.pfx_sunray_flare, 9, caster, PATTACH_POINT_FOLLOW, "attach_mouth", caster:GetAbsOrigin(), true )

	-- Swap sub ability
	local main_ability_name	= "phoenix_sun_ray_lua"
	local sub_ability_name	= "phoenix_sun_ray_stop_lua"
	caster:SwapAbilities( main_ability_name, sub_ability_name, false, true )

	local toggle_move = caster:FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
	if toggle_move then
		toggle_move:SetActivated(true)
	end
	self:StartIntervalThink(self.tick_interval)
	-- self:OnIntervalThink()
end

function modifier_phoenix_sun_ray_lua:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	-- 射线的伤害越来越强是根据时间决定的，而不是叠加在目标身上的光环数量决定的
	caster:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_lua_thinker", { duration = self.tick_interval * 1.9 })
	self:CostHealth(caster)

	-- Dmg and heal
	local units = FindUnitsInLine(caster:GetTeamNumber(),
		caster:GetAbsOrigin() + caster:GetForwardVector() * 32 ,
		caster.endcapPos,
		nil,
		ability:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE)
	for _,unit in pairs(units) do
		if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
			-- 敌方加debuff，对技能免疫单位（或远古单位）无效
			if (not unit:IsMagicImmune()) and (not unit:IsInvulnerable()) then
				-- unit:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_lua_debuff", { duration = self.tick_interval* (1 - unit:GetStatusResistance()) } )
				self:DamageIt(unit)
			end
		elseif unit ~= caster then
			-- 非自己的友方加buff，对信使无效，对技能免疫友方有效
			-- unit:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_lua_buff", { duration = self.tick_interval} )
			self:HealIt(unit)
		end
	end
end

function modifier_phoenix_sun_ray_lua:OnDestroy()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	caster:RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_3)
	StartSoundEvent("Hero_Phoenix.SunRay.Stop", caster)
	StopSoundEvent( "Hero_Phoenix.SunRay.Loop", caster)
	if self.pfx_sunray_flare then
		ParticleManager:DestroyParticle(self.pfx_sunray_flare, false)
		ParticleManager:ReleaseParticleIndex(self.pfx_sunray_flare)
	end
	-- Swap sub ability
	self:OnModifierFinish()
	caster:SetContextThink( DoUniqueString("waitToFindClearSpace"), function ( )
		if not caster:HasModifier("modifier_naga_siren_song_of_the_siren") then
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin() , false)
			return nil
		end
		return 0.1
	end, 0 )
end

-- 自定义函数
function modifier_phoenix_sun_ray_lua:GetToggleMoveState()
    local caster = self:GetCaster()
    -- local isActived = brother_ability:IsActivated()
    local isToggled = caster.sun_ray_is_moving
    --local isDiving = caster:HasModifier("modifier_phoenix_icarus_dive_lua")
    -- print("isActived:"..tostring(isActived).."isToggled:"..tostring(isToggled))
    return not isToggled
end

function modifier_phoenix_sun_ray_lua:OnModifierFinish()
    local brother_ability = self:GetParent():FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
	if brother_ability then
		brother_ability:SetActivated(false)
	end
    self:GetParent():SwapAbilities("phoenix_sun_ray_lua","phoenix_sun_ray_stop_lua",true,false)
end

function modifier_phoenix_sun_ray_lua:CostHealth(caster)
    local heal_cost_pct = self.hp_cost_perc_per_second / 100
    local tick_per_sec = 1 / self.tick_interval
    local heal_cost_per_tick = heal_cost_pct / tick_per_sec
    local heal_cost_this_time = caster:GetHealth() * heal_cost_per_tick

    if (caster:GetHealth() - heal_cost_this_time) <= 1 then
        caster:SetHealth(1)
    else
        caster:SetHealth( caster:GetHealth() - heal_cost_this_time )
    end
end

function modifier_phoenix_sun_ray_lua:DamageIt(taker)
	--self.base_damage	= self:GetAbility():GetSpecialValueFor("base_damage")
	--self.hp_perc_damage	= self:GetAbility():GetSpecialValueFor("hp_perc_damage")
    self.inc_dmg_per_tick	= self:GetAbility():GetSpecialValueFor("inc_dmg_per_tick")
    self.inc_dmg_pct_per_tick	= self:GetAbility():GetSpecialValueFor("inc_dmg_pct_per_tick")
	self.tick_interval	= self:GetAbility():GetSpecialValueFor("tick_interval")

	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	local caster = self:GetCaster()

	if not caster:HasModifier("modifier_phoenix_sun_ray_lua_thinker") then
		return
	end

	local num_stack = caster:FindModifierByName("modifier_phoenix_sun_ray_lua_thinker"):GetStackCount()

	local base_dmg = self.base_damage
	local taker_health = taker:GetMaxHealth()
    -- base_dmg 和 hp_perc_damage 其实是随时间增加的伤害量后最后一次的最大伤害量
	-- local total_damage = (base_dmg + taker_health * self.hp_perc_damage / 100) * self.tick_interval
    -- 随时间增加的伤害
    total_damage = (self.inc_dmg_per_tick + taker_health*self.inc_dmg_pct_per_tick/100)* num_stack
	local damageTable = {
		victim = taker,
		attacker = caster,
		damage = total_damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	}
	ApplyDamage(damageTable)
    print("伤害敌人！"..tostring(total_damage).."stack:"..num_stack)
end

function modifier_phoenix_sun_ray_lua:HealIt(taker)
	--self.base_heal	= self:GetAbility():GetSpecialValueFor("base_heal")
	--self.hp_perc_heal	= self:GetAbility():GetSpecialValueFor("hp_perc_heal")
    self.inc_heal_per_tick	= self:GetAbility():GetSpecialValueFor("inc_heal_per_tick")
    self.inc_heal_pct_per_tick	= self:GetAbility():GetSpecialValueFor("inc_heal_pct_per_tick")
	self.tick_interval	= self:GetAbility():GetSpecialValueFor("tick_interval")

	if not IsServer() then
		return
	end

	local ability = self:GetAbility()
	local caster = self:GetCaster()

	if not caster:HasModifier("modifier_phoenix_sun_ray_lua_thinker") then
		return
	end

	local num_stack = caster:FindModifierByName("modifier_phoenix_sun_ray_lua_thinker"):GetStackCount()

	local base_heal = self.base_heal
	local taker_health = taker:GetMaxHealth()
    -- base_heal和hp_perc_heal其实是随时间增加的治疗量后最后一次的最大治疗量
	-- local total_heal = (base_heal + taker_health * self.hp_perc_heal / 100)*self.tick_interval
    -- 随时间增加的治疗量
    total_heal = (self.inc_heal_per_tick + taker_health*self.inc_heal_pct_per_tick/100)* num_stack

    taker:Heal(total_heal,ability)
    print("治疗队友！"..tostring(total_heal).."stack:"..num_stack)
end
