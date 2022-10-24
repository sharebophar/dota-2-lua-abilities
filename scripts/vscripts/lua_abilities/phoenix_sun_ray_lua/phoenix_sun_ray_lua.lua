--[[
phoenix_sun_ray_lua = class({})
LinkLuaModifier( "modifier_phoenix_sun_ray_lua", "lua_abilities/phoenix_sun_ray_lua/modifier_phoenix_sun_ray_lua", LUA_MODIFIER_MOTION_NONE )

function phoenix_sun_ray_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

    caster:AddNewModifier(
        caster,
        self,
        "modifier_phoenix_sun_ray_lua",
        {
            duration = self:GetDuration(),
        }
    )

    caster:SwapAbilities("phoenix_sun_ray_lua","phoenix_sun_ray_stop_lua",false,true)
end

function phoenix_sun_ray_lua:OnUpgrade()
    local sister_ability = self:GetCaster():FindAbilityByName("phoenix_sun_ray_stop_lua")
    sister_ability:UpgradeAbility(true)

    local brother_ability = self:GetCaster():FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
    brother_ability:UpgradeAbility(true)
    brother_ability:SetActivated(self:GetCaster():HasModifier("modifier_phoenix_sun_ray_lua"))
end
]]

LinkLuaModifier("modifier_phoenix_sun_ray_lua",         "lua_abilities/phoenix_sun_ray_lua/modifier_phoenix_sun_ray_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_sun_ray_lua_thinker", "lua_abilities/phoenix_sun_ray_lua/modifier_phoenix_sun_ray_lua_thinker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_sun_ray_lua_buff",    "lua_abilities/phoenix_sun_ray_lua/modifier_phoenix_sun_ray_lua_buff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_sun_ray_lua_debuff",  "lua_abilities/phoenix_sun_ray_lua/modifier_phoenix_sun_ray_lua_debuff", LUA_MODIFIER_MOTION_NONE)

phoenix_sun_ray_lua = class({})

function phoenix_sun_ray_lua:IsHiddenWhenStolen() 		return false end
function phoenix_sun_ray_lua:IsRefreshable() 			return true  end
function phoenix_sun_ray_lua:IsStealable() 			return true  end
function phoenix_sun_ray_lua:IsNetherWardStealable() 	return true  end
function phoenix_sun_ray_lua:GetAssociatedSecondaryAbilities()  return "phoenix_sun_ray_toggle_move_lua" end
function phoenix_sun_ray_lua:GetAbilityTextureName()   return "phoenix_sun_ray" end

--[[
function phoenix_sun_ray_lua:OnStolen(self)
	if not self:GetCaster():HasAbility("phoenix_sun_ray_stop_lua") then
		self:GetCaster():AddAbility("phoenix_sun_ray_stop_lua"):SetHidden(true)
		self:GetCaster():FindAbilityByName("phoenix_sun_ray_stop_lua"):SetLevel(1)
	end
end

-- SPAGHET
function phoenix_sun_ray_lua:OnUnStolen()
	if self:GetCaster():HasAbility("phoenix_sun_ray_stop_lua") then		
		if not self:GetCaster():FindAbilityByName("phoenix_sun_ray_stop_lua"):IsHidden() then
			self:GetCaster():SwapAbilities(self:GetName(), "phoenix_sun_ray_stop_lua", true, false)
		end
		
		self:GetCaster():RemoveAbility("phoenix_sun_ray_stop_lua")
		self:GetCaster():RemoveModifierByName("modifier_phoenix_sun_ray_lua")
	end
end
]]

function phoenix_sun_ray_lua:OnSpellStart()
    self.tick_interval = self:GetSpecialValueFor("tick_interval") 
	-- SUPER rough Morphling check for now
    --[[
	if self:GetCaster():HasModifier("modifier_morphling_replicate") then
		self:GetCaster():AddAbility("phoenix_sun_ray_stop_lua"):SetHidden(true)
		self:GetCaster():FindAbilityByName("phoenix_sun_ray_stop_lua"):SetLevel(1)
	end
	]]
	-- Preventing projectiles getting stuck in one spot due to potential 0 length vector
	if self:GetCursorPosition() == self:GetCaster():GetAbsOrigin() then
		self:GetCaster():SetCursorPosition(self:GetCursorPosition() + self:GetCaster():GetForwardVector())
	end	

	local caster	= self:GetCaster()
	local ability	= self
    
	local ray_stop = caster:FindAbilityByName("phoenix_sun_ray_stop_lua")
	local toggle_move = caster:FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
	if not ray_stop or not toggle_move then
		caster:RemoveAbility("phoenix_sun_ray_lua")
		return
	end

	local pathLength					= 1200
	local max_duration 					= self:GetDuration()
	local forwardMoveSpeed				= self:GetSpecialValueFor("forward_move_speed")
	local turnRateInitial				= self:GetSpecialValueFor("turn_rate_initial")
	local turnRate						= self:GetSpecialValueFor("turn_rate")
	local initialTurnDuration			= 0.75 -- 施法时转身到目标方向所需时间
	local vision_radius					= self:GetSpecialValueFor("radius") / 2
	local numVision						= math.ceil( pathLength / vision_radius )
	local modifierCasterName			= "modifier_phoenix_sun_ray_lua"

	local casterOrigin	= caster:GetAbsOrigin()

	caster:AddNewModifier(caster, ability, modifierCasterName, { duration = max_duration })

	caster.sun_ray_is_moving = false
	caster.sun_ray_hp_at_start = caster:GetHealth()

	-- Create particle FX
	local particleName = "particles/units/heroes/hero_phoenix/phoenix_sunray.vpcf"
	local pfx = ParticleManager:CreateParticle( particleName, PATTACH_WORLDORIGIN, nil )
	local attach_point = caster:ScriptLookupAttachment( "attach_head" )
	-- Attach a loop sound to the endcap
	local endcapSoundName = "Hero_Phoenix.SunRay.Beam"
	StartSoundEvent( endcapSoundName, endcap )
	StartSoundEvent("Hero_Phoenix.SunRay.Cast", caster)

    -- 技能开启后凤凰不是立马转过来的，而是有一个转过来的过程
	--
	-- Note: The turn speed
	--
	--  Original's actual turn speed = 277.7735 (at initial) and 22.2218 [deg/s].
	--  We can achieve this weird value by using this formula.
	--	  actual_turn_rate = turn_rate / (0.0333..) * 0.03
	--
	--  And, initial turn buff ends when the delta yaw gets 0 or 0.75 seconds elapsed.
	--
	turnRateInitial	= turnRateInitial	/ (1/30) * 0.03
	turnRate		= turnRate			/ (1/30) * 0.03

	-- Update
	local deltaTime = 0.03

	local lastAngles = caster:GetAngles()
	local isInitialTurn = true
	local elapsedTime = 0.0

    local function CheckForCanceled(caster)
        return caster:IsStunned() or caster:IsHexed() or caster:IsNightmared() or caster:HasModifier("modifier_naga_siren_song_of_the_siren") or caster:HasModifier("modifier_eul_cyclone") or caster:IsFrozen() or caster:IsOutOfGame()
    end
	caster:SetContextThink( DoUniqueString( "updateSunRay" ), function ( )
		-- Mars' Arena of Blood exception
		if self:GetCaster():HasModifier("modifier_mars_arena_of_blood_leash") and self:GetCaster():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner() and (self:GetCaster():GetAbsOrigin() - self:GetCaster():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner():GetAbsOrigin()):Length2D() >= self:GetCaster():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("radius") - self:GetCaster():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("width") then
			self:GetCaster():RemoveModifierByName("modifier_phoenix_sun_ray_lua")
		end

        ParticleManager:SetParticleControl(pfx, 0, caster:GetAttachmentOrigin(attach_point))
        -- Check the Debuff that can interrupt spell
        if (CheckForCanceled( caster ) and ((not self:GetCaster():HasScepter()) or (self:GetCaster():HasScepter() and not self:GetCaster():HasModifier("modifier_phoenix_supernova_hide_effect")))) or caster:IsSilenced() or caster:HasModifier("modifier_legion_commander_duel") or caster:HasModifier("modifier_lone_druid_savage_roar") then
            caster:RemoveModifierByName("modifier_phoenix_sun_ray_lua")
        end

        -- OnInterrupted :
        --  Destroy FXs and the thinkers.

        if not caster:HasModifier( modifierCasterName ) then
            ParticleManager:DestroyParticle( pfx, false )
            StopSoundEvent( endcapSoundName, endcap )
            caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
            return nil
        end

        -- Cut Trees
        local pos = caster:GetAbsOrigin()
        GridNav:DestroyTreesAroundPoint(pos, 128, false)

        -- 距离是32
        -- "MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE" is seems to be broken.
        -- So here we fix the yaw angle manually in order to clamp the turn speed.
        --
        -- If the hero has "modifier_ignore_turn_rate_limit_datadriven" modifier,
        -- we shouldn't change yaw from here.
        --
        -- Calculate the turn speed limit.
        local deltaYawMax

        if isInitialTurn then
            deltaYawMax = turnRateInitial * deltaTime
        else
            deltaYawMax = turnRate * deltaTime
        end

        -- Calculate the delta yaw
        local currentAngles	= caster:GetAngles()
        local deltaYaw		= RotationDelta( lastAngles, currentAngles ).y
        local deltaYawAbs	= math.abs( deltaYaw )

        -- 
        if deltaYawAbs > deltaYawMax and not caster:HasModifier( "modifier_phoenix_icarus_dive_lua" ) then
            -- Clamp delta yaw
            local yawSign = (deltaYaw < 0) and -1 or 1
            local yaw = lastAngles.y + deltaYawMax * yawSign

            currentAngles.y = yaw	-- Never forget!

            -- Update the yaw
            caster:SetAbsAngles( currentAngles.x, currentAngles.y, currentAngles.z )
        end

        lastAngles = currentAngles

        -- Update the turning state.
        elapsedTime = elapsedTime + deltaTime

        if isInitialTurn then
            if deltaYawAbs == 0 then
                isInitialTurn = false
            end
            if elapsedTime >= initialTurnDuration then
                isInitialTurn = false
            end
        end

        -- Current position & direction
        local casterOrigin	= caster:GetAbsOrigin()
        local casterForward	= caster:GetForwardVector()

        -- Move forward
        if caster.sun_ray_is_moving and not GameRules:IsGamePaused() then
            casterOrigin = casterOrigin + casterForward * forwardMoveSpeed * deltaTime
            casterOrigin = GetGroundPosition( casterOrigin, caster )
            caster:SetAbsOrigin( casterOrigin )
        end

        -- Update thinker positions
        local endcapPos = casterOrigin + casterForward * pathLength
        endcapPos = GetGroundPosition( endcapPos, nil )
        endcapPos.z = endcapPos.z + 92

        -- Update particle FX
        ParticleManager:SetParticleControl( pfx, 1, endcapPos )
        caster.endcapPos = endcapPos
--[[
        -- Dmg and heal
        local units = FindUnitsInLine(caster:GetTeamNumber(),
            caster:GetAbsOrigin() + caster:GetForwardVector() * 32 ,
            endcapPos,
            nil,
            ability:GetSpecialValueFor("radius"),
            DOTA_UNIT_TARGET_TEAM_BOTH,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE)
        for _,unit in pairs(units) do
            if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
                -- 敌方加debuff，对技能免疫单位（或远古单位）无效
                if (not unit:IsMagicImmune()) and (not unit:IsInvulnerable()) then
                    unit:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_lua_debuff", { duration = self.tick_interval* (1 - unit:GetStatusResistance()) } )
                    -- self:DamageIt(unit)
                end
            elseif unit ~= caster then
                -- 非自己的友方加buff，对信使无效，对技能免疫友方有效
                unit:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_lua_buff", { duration = self.tick_interval} )
                -- self:HealIt(unit)
            end
        end
]]
        -- Give vision
        for i=1, numVision do
            AddFOWViewer(caster:GetTeamNumber(), ( casterOrigin + casterForward * ( vision_radius * 2 * (i-1) ) ), vision_radius, deltaTime, false)
        end

        return deltaTime

	end, 0 )

end

function phoenix_sun_ray_lua:OnUpgrade()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	
	caster.sun_ray_is_moving = false

	-- The ability to level up
	local ray_stop = caster:FindAbilityByName("phoenix_sun_ray_stop_lua")
	if ray_stop then
		ray_stop:SetLevel(1)
	end

	local toggle_move = caster:FindAbilityByName("phoenix_sun_ray_toggle_move_lua")
	if toggle_move then
		toggle_move:SetLevel(1)
		toggle_move:SetActivated(false)
	end

end