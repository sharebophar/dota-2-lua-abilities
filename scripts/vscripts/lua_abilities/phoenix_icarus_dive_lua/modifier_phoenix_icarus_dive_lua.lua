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
	return true
end

function modifier_phoenix_icarus_dive_lua:IsStunDebuff()
	return true
end

function modifier_phoenix_icarus_dive_lua:IsPurgable()
	return true
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

	self.tick_cur_times = 1
	self.tick_total_times = 36 -- 椭圆分36次移动完成，固定时间段内移动的距离不同，故移动速度不同
	self.angle_per_tick = 360/self.tick_total_times
	self.think_tick = self.dive_duration * self.angle_per_tick/360
	self:GenMovePathData()

	self:StartIntervalThink(self.think_tick)
	self:OnIntervalThink()

	-- 移动轨迹要自己计算
	--[[
	self.target = Vector( kv.pos_x, kv.pos_y, 0 )

	-- get speed
	local dist = (self:GetParent():GetOrigin()-self.target):Length2D()
	self.speed = kv.pull/100*dist/kv.duration

	if not self:GetParent():IsHero() then
		self.speed = nil
	end

	-- issue a move command
	self:GetParent():MoveToPosition( self.target )
	]]
end

function modifier_phoenix_icarus_dive_lua:OnRefresh( kv )
	-- self:OnCreated( kv )
	-- Refresh时，只更新配置数值
end

function modifier_phoenix_icarus_dive_lua:OnRemoved()
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
		[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
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
		local MovePointData = self.MovePathData[self.tick_cur_times]
		self.speed = MovePointData.move_speed
		self:GetParent():MoveToPosition(MovePointData.next_position)

		self.tick_cur_times = self.tick_cur_times + 1
	else
		self:StartIntervalThink(-1)
		self:GetParent():SwapAbilities("phoenix_icarus_dive_lua","phoenix_icarus_dive_stop_lua",true,false)
	end
end


-- 自定义方法
function modifier_phoenix_icarus_dive_lua:GetDistance(point1,point2,ignoreZ)
	if ignoreZ then
		point1.z = 0
		point2.z = 0
	end
	return (point1-point2):Length()
end

function modifier_phoenix_icarus_dive_lua:GetIcarusDiveRadian()
	local target_point = self:GetAbility():GetCursorPosition()
	local unit_point = self:GetParent():GetAbsOrigin()
	local radian = math.atan2((target_point.y - unit_point.y),(target_point.x - unit_point.x))
	return radian
end

-- 通过长短轴，角度，近拱点获得近焦点，远焦点，远拱点 坐标
function modifier_phoenix_icarus_dive_lua:GetFocalPoint(mPeriapsis,width,length)
	local radian = self:GetIcarusDiveRadian()
	local c = math.sqrt(length*length-width*width)
	local perifocus_dist = length/2 - c
	local apofocus_dist = length/2 + c
	local nomal_vector = Vector(math.cos(radian),math.sin(radian),0)
	--local nomal_vector = Vector(1,0,0)
	local perifocus = perifocus_dist * nomal_vector + mPeriapsis
	local apofocus = apofocus_dist * nomal_vector + mPeriapsis
	local apoapsisPos = length * nomal_vector + mPeriapsis
	return perifocus,perifocus,apoapsisPos
end

-- 循环方向，初始点，时间，每次增加的角度（外切圆的），长轴，短轴
function modifier_phoenix_icarus_dive_lua:GetOvalPosition(mPeriapsis,time,mAngle,width,length,mDirection)
	-- mDirection代表点在椭圆上的运动方向是顺时针还是逆时针，angle用于计算椭圆参数方程的角度
	-- double angle = (mDirection == OrbitDirection.CLOCKWISE ? -1 : 1) * mAngle * time * MathUtil.PRE_PI_DIV_180;
	local angle = (mDirection and -1 or 1) * mAngle * time * math.pi/180 -- 不填mDirection的话默认顺时针

	-- 计算近拱点到焦点的距离，近拱点就是单位当前所在的点
	local mFocalPoint,_,apoapsisPos = self:GetFocalPoint(mPeriapsis,width,length)
	-- 根据离心率、近拱点到焦点的距离、远拱点到焦点三者的公式即可得到远拱点距离(近拱点到远拱点的距离是椭圆的长轴)
	-- double apoapsisRadius = periapsisRadius * (1 + mEccentricity) / (1 - mEccentricity);
	
	-- 近拱点和远拱点的中心即椭圆的中心
	local center = (mPeriapsis + apoapsisPos)/2
	
	-- 计算半短轴的长度
	local b = width/2

	-- 从中心点到近拱点的向量
	local semimajorAxis = mPeriapsis - center


	--单位化半长轴向量
	local unitSemiMajorAxis = semimajorAxis:Normalized()
	
	-- 方向向量就是z轴
	local unitNormal = Vector(0,0,1)
	-- 原算法里加了这个偏移，我看不明白，应该是个错误
	-- local normalCenter = center + unitNormal
	--叉乘计算半短轴的单位向量
	--Vector3 semiminorAxis = mScratch3.crossAndSet(mScratch1, mScratch2);
	local semiminorAxis = unitSemiMajorAxis:Cross(unitNormal)
	--得到半短轴向量
	--semiminorAxis.multiply(b);
	semiminorAxis = semiminorAxis * b

	-- 计算3d坐标点
	local x = center.x + (math.cos(angle) * semimajorAxis.x) + (math.sin(angle) * semiminorAxis.x);
	local y = center.y + (math.cos(angle) * semimajorAxis.y) + (math.sin(angle) * semiminorAxis.y);
	local z = center.z + (math.cos(angle) * semimajorAxis.z) + (math.sin(angle) * semiminorAxis.z);
	
	-- print("("..math.floor(x)..","..math.floor(y)..")")
	return Vector(x,y,z)
end

-- 计算飞行的各个点和到达点后的移动速度，在Create时调用
function modifier_phoenix_icarus_dive_lua:GenMovePathData()
	self.start_position = self:GetParent():GetAbsOrigin()
	local _next_position = self:GetOvalPosition(self.start_position,1,self.angle_per_tick,self.dash_width,self.dash_length)
	local _move_speed = self:GetDistance(self.start_position,_next_position)/self.think_tick
	self.MovePathData = {{next_position = _next_position,move_speed = _move_speed}}
	for i=2,self.tick_total_times do
		local time = i * self.think_tick
		local cur_position = self.MovePathData[i-1].next_position
		_next_position = self:GetOvalPosition(self.start_position,i,self.angle_per_tick,self.dash_width,self.dash_length)
		_move_speed = self:GetDistance(cur_position,_next_position)/self.think_tick
		table.insert(self.MovePathData,{next_position = _next_position,move_speed = _move_speed})
	end
end