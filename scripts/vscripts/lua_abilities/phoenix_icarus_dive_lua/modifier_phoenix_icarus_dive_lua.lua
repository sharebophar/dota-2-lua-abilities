-- Created by Elfansoer
--[[
-- 参考紫猫的残阴 aether_remnant，写强制路径移动技能
]]
--------------------------------------------------------------------------------
modifier_phoenix_icarus_dive_lua = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_phoenix_icarus_dive_lua:IsHidden()
	return false
end

function modifier_phoenix_icarus_dive_lua:IsDebuff()
	return false
end

function modifier_phoenix_icarus_dive_lua:IsStunDebuff()
	return false
end

function modifier_phoenix_icarus_dive_lua:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_phoenix_icarus_dive_lua:OnCreated( kv )
	-- references
	if not IsServer() then return end
	self.hp_cost_perc = self:GetAbility():GetSpecialValueFor("hp_cost_perc")
	self.dash_length = self:GetAbility():GetSpecialValueFor("dash_length")
	self.dash_width = self:GetAbility():GetSpecialValueFor("dash_width")
	self.hit_radius = self:GetAbility():GetSpecialValueFor("hit_radius")
	self.burn_duration = self:GetAbility():GetSpecialValueFor("burn_duration")
	self.damage_per_second = self:GetAbility():GetSpecialValueFor("damage_per_second")
	self.burn_tick_interval = self:GetAbility():GetSpecialValueFor("burn_tick_interval")
	self.slow_movement_speed_pct = self:GetAbility():GetSpecialValueFor("slow_movement_speed_pct")
	self.dive_duration = self:GetAbility():GetSpecialValueFor("dive_duration")

	self.passed_time = 0
	local caster = self:GetCaster()
	self.caster_origin	= caster:GetAbsOrigin()
	self.caster_angles	= caster:GetAngles()
	self.forward_dir	= caster:GetForwardVector()
	self.right_dir		= caster:GetRightVector()

	--caster:SetAngles( casterAngles.x, yaw, casterAngles.z )

	self.ellipse_center	= self.caster_origin + self.forward_dir * ( self.dash_length * 0.5 )

	self.tick_cur_times = 1
	self.tick_total_times = 36 -- 椭圆分36次移动完成，固定时间段内移动的距离不同，故移动速度不同
	self.angle_per_tick = 360/self.tick_total_times
	self.think_tick = self.dive_duration * self.angle_per_tick/360
	-- self:GenMovePathData()

	self:StartIntervalThink(self.think_tick)
	self:OnIntervalThink()

	self.pfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_phoenix/phoenix_icarus_dive.vpcf", PATTACH_WORLDORIGIN, nil )
	
	if self:ApplyHorizontalMotionController() == false then 
		print("ApplyHorizontalMotionController failed!")
		self:OnModifierFinish()
		self:Destroy()
	end
	-- 禁用烈日炙烤
	local brother_ability = self:GetCaster():FindAbilityByName("phoenix_sun_ray_lua")
	if brother_ability then
    	brother_ability:SetActivated(false)
	end
end

function modifier_phoenix_icarus_dive_lua:OnRefresh( kv )
	-- self:OnCreated( kv )
	-- Refresh时，只更新配置数值
end

function modifier_phoenix_icarus_dive_lua:OnRemoved()
	-- 启用烈日炙烤
	--local brother_ability = self:GetCaster():FindAbilityByName("phoenix_sun_ray_lua")
	--if brother_ability then
    --	brother_ability:SetActivated(true)
	--end
end

function modifier_phoenix_icarus_dive_lua:OnDestroy()
	self:StartIntervalThink(-1)
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_phoenix_icarus_dive_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
	}

	return funcs
end

function modifier_phoenix_icarus_dive_lua:GetModifierMoveSpeed_Absolute()
	if IsServer() then return self.speed end
end
--------------------------------------------------------------------------------
-- Status Effects
function modifier_phoenix_icarus_dive_lua:CheckState()
	local state = {
		-- [MODIFIER_STATE_COMMAND_RESTRICTED] = true, -- 不能放技能
		-- [MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true, -- 不能攻击
		-- [MODIFIER_STATE_ROOTED] = true, -- 不是禁止移动，是禁止执行移动指令；飞行中能攻击
		-- [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_ALLOW_PATHING_THROUGH_FISSURE] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_phoenix_icarus_dive_lua:GetStatusEffectName()
	-- return "particles/status_fx/status_effect_void_spirit_aether_remnant.vpcf"
end

function modifier_phoenix_icarus_dive_lua:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

function modifier_phoenix_icarus_dive_lua:OnIntervalThink()

	if self.tick_cur_times <= self.tick_total_times then
		--local MovePointData = self.MovePathData[self.tick_cur_times]
		--self.speed = MovePointData.move_speed
		--self:GetParent():MoveToPosition(MovePointData.next_position)

		self.tick_cur_times = self.tick_cur_times + 1
	else
		self:StartIntervalThink(-1)
		-- self:OnModifierFinish()
	end
end

--------------------------------------------------------------------------------
-- Motion Effects
function modifier_phoenix_icarus_dive_lua:UpdateHorizontalMotion( me, dt )
	self.passed_time = self.passed_time + dt
	local progress = self.passed_time / self.dive_duration
	-- Calculate potision
	local theta = -2 * math.pi * progress
	local x =  math.sin( theta ) * self.dash_width * 0.5
	local y = -math.cos( theta ) * self.dash_length * 0.5

	local pos = self.ellipse_center + self.right_dir * x + self.forward_dir * y
	local yaw = self.caster_angles.y + 90 + progress * -360  

	pos = GetGroundPosition( pos, me )
	me:SetAbsOrigin( pos )
	me:SetAbsAngles( self.caster_angles.x, yaw, self.caster_angles.z )

	-- Cut Trees
	GridNav:DestroyTreesAroundPoint(pos, 80, false)
	-- print("UpdateHorizontalMotion"..tostring(pos))

	ParticleManager:SetParticleControl(self.pfx, 0, me:GetAbsOrigin() + me:GetRightVector() * 32 )
	-- Find Enemies apply the debuff
	local enemies = FindUnitsInRadius(me:GetTeamNumber(),
		me:GetAbsOrigin(),
		nil,
		self.hit_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)
	for _,enemy in pairs(enemies) do
		-- 更新过快，防止重复加buff
		if not enemy:HasModifier("modifier_phoenix_icarus_dive_lua_slow_debuff") then
			enemy:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_phoenix_icarus_dive_lua_slow_debuff", {duration = self.burn_duration} )
			print("加减速debuff哦")
		end
	end
	enemies = nil -- 赋予空值，加速垃圾回收
	if progress >= 1 then
		self:OnModifierFinish()
	end
end

function modifier_phoenix_icarus_dive_lua:OnHorizontalMotionInterrupted()
	print("OnHorizontalMotionInterrupted")
	self:OnModifierFinish()
	self:Destroy()
end

function modifier_phoenix_icarus_dive_lua:OnModifierFinish()
	if self.pfx then
		print("销毁特效OnFinish")
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end
	self:GetParent():RemoveHorizontalMotionController( self )
	local brother_ability = self:GetCaster():FindAbilityByName("phoenix_sun_ray_lua")
	if brother_ability then
    	brother_ability:SetActivated(true)
	end
	self:GetParent():SwapAbilities("phoenix_icarus_dive_lua","phoenix_icarus_dive_stop_lua",true,false)
end