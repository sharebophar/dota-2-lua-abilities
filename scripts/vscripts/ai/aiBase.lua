EXPORTS = {}

EXPORTS.Init = function( self )
	-- Defer the initialization to first tick, to allow spawners to set state.
	self.aiState = {
		hAggroTarget = nil,             -- 仇恨目标
		flShoutRange = 0,               -- 呼叫同伴（仇恨传递）范围
		nWalkingMoveSpeed = 0,          -- 闲逛移动速度
		nAggroMoveSpeed = 0,            -- 仇恨移动速度
		flAcquisitionRange = 700,       -- 默认攻击范围
		vTargetWaypoint = nil,          -- 寻路点
	}
	self:SetContextThink( "init_think", function() 
		self.aiThink = aiThink
		self.CheckIfHasAggro = CheckIfHasAggro
		self.ShoutInRadius = ShoutInRadius
		self.RoamBetweenWaypoints = RoamBetweenWaypoints
        self:SetAcquisitionRange( self.aiState.flAcquisitionRange )

	    -- Generate nearby waypoints for this unit
	    local tWaypoints = {}
	    local nWaypointsPerRoamNode = 10
	    local nMinWaypointSearchDistance = 0
	    local nMaxWaypointSearchDistance = 2048

	    while #tWaypoints < nWaypointsPerRoamNode do
	    	local vWaypoint = self:GetAbsOrigin() + RandomVector( RandomFloat( nMinWaypointSearchDistance, nMaxWaypointSearchDistance ) )
	    	if GridNav:CanFindPath( self:GetAbsOrigin(), vWaypoint ) then
	    		table.insert( tWaypoints, vWaypoint )
	    	end
	    end
	    self.aiState.tWaypoints = tWaypoints
	    self:SetContextThink( "ai_base_creature.aiThink", Dynamic_Wrap( self, "aiThink" ), 0 )
	end, 0 )
end


function aiThink( self )
    if not self:IsAlive() then
    	return
    end
	if GameRules:IsGamePaused() then
		return 0.1
	end
	if self:CheckIfHasAggro() then
		return RandomFloat( 0.5, 1.5 )
	end
	return self:RoamBetweenWaypoints()
end

--------------------------------------------------------------------------------
-- CheckIfHasAggro 检查是否有仇恨目标
--------------------------------------------------------------------------------
function CheckIfHasAggro( self )
    if self:GetAggroTarget() ~= nil then
        -- 有仇恨目标时，设置奔跑速度
        self:SetBaseMoveSpeed( self.aiState.nAggroMoveSpeed )
        -- 呼叫同伴
        if self:GetAggroTarget() ~= self.aiState.hAggroTarget then
            self.aiState.hAggroTarget = self:GetAggroTarget()
            self:ShoutInRadius()
        end
        return true
    else  	
        -- 没有仇恨目标时，设置走路速度
        self:SetBaseMoveSpeed( self.aiState.nWalkingMoveSpeed )
        return false
    end
end

--------------------------------------------------------------------------------
-- ShoutInRadius 呼叫同伴
--------------------------------------------------------------------------------
function ShoutInRadius( self )
    local tNearbyCreatures = Entities:FindAllByClassnameWithin( "npc_dota_creature", self:GetOrigin(), self.aiState.flShoutRange )
    for k, hCreature in pairs( tNearbyCreatures ) do
        if hCreature:GetAggroTarget() == nil then -- only set new attack target on the creature if it doesn't already have an aggro target
            hCreature:MoveToTargetToAttack( self.aiState.hAggroTarget )
        end
    end
end


--------------------------------------------------------------------------------
-- RoamBetweenWaypoints 在给定的路点上闲逛
--------------------------------------------------------------------------------
function RoamBetweenWaypoints( self )
	local gameTime = GameRules:GetGameTime()
	local aiState = self.aiState
    -- 移动速度不为0时才闲逛
    if aiState.nWalkingMoveSpeed > 0 then
        if aiState.vWaypoint ~= nil then
            local flRoamTimeLeft = aiState.flNextWaypointTime - gameTime
            if flRoamTimeLeft <= 0 then
                aiState.vWaypoint = nil
            end
        end
        if aiState.vWaypoint == nil then
            aiState.vWaypoint = aiState.tWaypoints[ RandomInt( 1, #aiState.tWaypoints ) ]
            aiState.flNextWaypointTime = gameTime + RandomFloat( 2, 4 )
            self:MoveToPositionAggressive( aiState.vWaypoint )
        end
    end
   	return RandomFloat( 0.5, 1.0 )
end

return EXPORTS