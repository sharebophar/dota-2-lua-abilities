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

-- 死亡守卫并不是时时刻刻都在找最近的目标攻击，而是当“已选定的当前最近目标”离开攻击范围后才改向攻击最近目标
function modifier_witch_doctor_death_ward_lua_effect:ChangeTarget()
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

    -- 攻击附近的最近一个单位
    if enemies[1] then
        self.target = enemies[1]
    end
end
--------------------------------------------------------------------------------
-- Interval Effects
function modifier_witch_doctor_death_ward_lua_effect:OnIntervalThink()
	-- self.hidden = true
    local ward_unit = self:GetParent()
    if self.target and self.target:IsAlive() then
        local range_to_target = ward_unit:GetRangeToUnit(self.target)
        if range_to_target > self.attack_range then
            self:ChangeTarget()
        end
        ward_unit:SetForceAttackTarget(self.target)

        -- 添加修改器应该在think时还是attack时？
        -- 死亡守卫是否具有攻击弹射以及100%克敌击先取决于“该时刻施法者是否拥有阿哈利姆神杖”而不是“施法时”
        local caster = self:GetCaster()
        local bScepter = caster:HasScepter()
        if not bScepter then return end
        -- 给目标添加一个弹射的修改器
        --[[
        target:AddNewModifier(
            caster, -- player source
            self:GetAbility(), -- ability source
            "modifier_witch_doctor_death_ward_lua_effect_thinker", -- modifier name
            {
                key = kv.key,
                duration = bounce_delay,
            } -- kv
        )
        ]]
    else
        -- 目标不存在或已死亡也切换目标
        self:ChangeTarget()
    end
end