modifier_witch_doctor_death_ward_lua_effect = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_death_ward_lua_effect:IsHidden()
	return false
end

function modifier_witch_doctor_death_ward_lua_effect:IsDebuff()
	return false
end

function modifier_witch_doctor_death_ward_lua_effect:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_death_ward_lua_effect:OnCreated( kv )
    if not IsServer() then return end
	-- references
    self.delay = kv.delay or 0
    self.attack_range = kv.attack_range
    -- print("modifier_witch_doctor_death_ward_lua_effect:OnCreated( kv )-----------radius is:",self.attack_range)
	-- 找最近的目标攻击

	if IsServer() then
		-- Start interval
		self:StartIntervalThink( self.delay )
        self:OnIntervalThink()
	end
end

function modifier_witch_doctor_death_ward_lua_effect:OnRefresh( kv )
	-- references
	self.delay = kv.delay or 0

    -- 按道理效果不会刷新
end

function modifier_witch_doctor_death_ward_lua_effect:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_witch_doctor_death_ward_lua_effect:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK,
	}

	return funcs
end

function modifier_witch_doctor_death_ward_lua_effect:OnAttack( params )
	if IsServer() then
		-- print("modifier_witch_doctor_death_ward_lua_effect:OnAttack")
	end
end
--------------------------------------------------------------------------------
-- Status Effects
function modifier_witch_doctor_death_ward_lua_effect:CheckState()
	local state = {
		[MODIFIER_STATE_INVULNERABLE] = true, -- 无敌的
        [MODIFIER_STATE_NO_HEALTH_BAR] = true, -- 不显示血条的
        [MODIFIER_STATE_UNSELECTABLE] = true, -- 不可被选中的
        [MODIFIER_STATE_UNTARGETABLE] = true, -- 不能作为目标的
        [MODIFIER_STATE_ROOTED] = true, -- 不能移动
	}

	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_witch_doctor_death_ward_lua_effect:OnIntervalThink()
	-- self.hidden = true
    local ward_unit = self:GetParent()
    local caster = ward_unit:GetOwner()
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        ward_unit:GetOrigin(),
        nil,
        self.attack_range or ward_unit:GetAcquisitionRange(),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, -- 最近的目标
        false
    )

    -- 攻击附近的最近一个单位，这里暂时不写蓝杖弹射效果
    if enemies[1] then
        ward_unit:SetForceAttackTarget(enemies[1])
    end
end