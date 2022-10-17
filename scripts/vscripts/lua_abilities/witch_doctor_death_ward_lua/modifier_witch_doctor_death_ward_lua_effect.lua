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
    self.delay = kv.delay or 1 -- self:GetParent():GetAttackSpeed() -- 看看这个攻击速度是不是kv配置中 AttackRate 的值
    -- print("死亡守卫的攻击间隔为：",self:GetParent():GetAttacksPerSecond())
    self.attack_range = kv.attack_range
    self.damage = kv.damage or 0
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
        [MODIFIER_STATE_DISARMED] = true, -- 缴械，发现生物基类的情况下会对目标普攻
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true, -- 没有单位碰撞
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
    local ward_unit = self:GetParent()
    if self.target and self.target:IsAlive() then
        local range_to_target = ward_unit:GetRangeToUnit(self.target)
        if range_to_target > self.attack_range then
            self:ChangeTarget()
        end
    else
        -- 目标不存在或已死亡也切换目标
        self:ChangeTarget()
    end
    if self.target then
        self:WardAttackToTarget(ward_unit)
    end
end

function modifier_witch_doctor_death_ward_lua_effect:WardAttackToTarget(ward_unit)
    -- 不能再用这个强制攻击接口，必须让死亡守卫模拟攻击指定目标，来找准bounce时机
    -- ward_unit:SetForceAttackTarget(self.target)
    local ability = self:GetAbility()
    local caster = ward_unit:GetOwner()
    -- load data
    local damage = ability:GetSpecialValueFor( "damage" )
    local scepter = false
    if caster:HasScepter() then
        -- damage = self:GetSpecialValueFor("damage_scepter")
        scepter = true
    end

    -- store data
    local castTable = {
        damage = damage,
        scepter = scepter,
        jump_range = ability:GetSpecialValueFor("bounce_radius"),
        bounced_targets = {self.target}, -- 被本次弹射攻击过的目标不会再被弹射，但仍可以被攻击
    }
    local key = tempTable:AddATValue( castTable )

    -- local projectile_name = "particles/econ/items/lich/lich_ti8_immortal_arms/lich_ti8_chain_frost.vpcf"
    local projectile_name = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf"
    -- 后面测试看看能不能改
    -- projectile_name = ward_unit:GetRangedProjectileName()
    local projectile_speed = self.target:GetProjectileSpeed()
    --local projectile_vision = self:GetSpecialValueFor("vision_radius")

    local projectile_info = {
        Target = self.target,
        Source = ward_unit,
        Ability = ability,	
        
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = false,                           -- Optional
    
        bVisibleToEnemies = true,                         -- Optional
        bProvidesVision = false,                           -- Optional
        --iVisionRadius = projectile_vision,                              -- Optional
        --iVisionTeamNumber = caster:GetTeamNumber(),        -- Optional
        ExtraData = {
            key = key,
        }
    }
    projectile_info = self:GetAbility():PlayProjectile( projectile_info )
    castTable.projectile = projectile_info
    ProjectileManager:CreateTrackingProjectile( castTable.projectile )

    -- 音效播放
    local sound_cast = "Hero_WitchDoctor_Ward.Attack"
    EmitSoundOn( sound_cast, caster )
end