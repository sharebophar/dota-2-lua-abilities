witch_doctor_death_ward_lua = class({})
LinkLuaModifier( "modifier_witch_doctor_death_ward_lua", "lua_abilities/witch_doctor_death_ward_lua/modifier_witch_doctor_death_ward_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_witch_doctor_death_ward_lua_effect", "lua_abilities/witch_doctor_death_ward_lua/modifier_witch_doctor_death_ward_lua_effect", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_witch_doctor_death_ward_lua_effect_thinker", "lua_abilities/witch_doctor_death_ward_lua/modifier_witch_doctor_death_ward_lua_effect_thinker", LUA_MODIFIER_MOTION_NONE )
--------------------------------------------------------------------------------
-- Ability Start
function witch_doctor_death_ward_lua:OnSpellStart()
    print("OnSpellStart:")
	-- unit identifier
	local caster = self:GetCaster()
    local position = self:GetCursorPosition()
	-- Add modifier
	self.modifier = caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_witch_doctor_death_ward_lua", -- modifier name
		{   duration = self:GetChannelTime(),
            createOnSpellStart = true,
        } -- kv
	)
    print("OnSpellStart Executed:")
end

--------------------------------------------------------------------------------
-- Ability Channeling
-- function witch_doctor_death_ward_lua:GetChannelTime()

-- end

function witch_doctor_death_ward_lua:OnChannelFinish( bInterrupted )
	if self.modifier then
		self.modifier:Destroy()
		self.modifier = nil
	end
end

--------------------------------------------------------------------------------
-- Ability Considerations
function witch_doctor_death_ward_lua:AbilityConsiderations()
	-- Scepter
	local bScepter = caster:HasScepter()

	-- Linken & Lotus
	local bBlocked = target:TriggerSpellAbsorb( self )

	-- Break
	local bBroken = caster:PassivesDisabled()

	-- Advanced Status
	local bInvulnerable = target:IsInvulnerable()
	local bInvisible = target:IsInvisible()
	local bHexed = target:IsHexed()
	local bMagicImmune = target:IsMagicImmune()

	-- Illusion Copy
	local bIllusion = target:IsIllusion()
end

--------------------------------------------------------------------------------
-- Projectile 特效击中事件
function witch_doctor_death_ward_lua:OnProjectileHit_ExtraData( target, location, kv )
	self:StopProjectile( kv )
	-- load data
	local bounce_delay = 0.22 
	local castTable = tempTable:GetATValue( kv.key ) -- tempTable可以用在不同作用域之间的传递数据，kv中不能传递的结构可以通过传递key来传递
	local damage = castTable.damage or 0
	print("弹射伤害为：",damage)
	-- 先造成伤害，有蓝杖才弹射
	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = self, --Optional.
	}
	ApplyDamage(damageTable)

	--local sound_target = "Hero_WitchDoctor_Ward.Attack"
	--EmitSoundOn( sound_target, target )

    -- 死亡守卫是否具有攻击弹射以及100%克敌击先取决于“该时刻施法者是否拥有阿哈利姆神杖”而不是“施法时”
	-- 所以判定是否有蓝杖不应该是从施法时传进来。
	-- 蓝杖的弹射是找最近的目标弹射，被某个子弹弹射过的目标不会再被弹射
    local caster = self:GetCaster()
    local bScepter = caster:HasScepter()
	-- 为测试方便，注释掉
    if not bScepter then return end
	-- bounce thinker
	-- 弹射命中时添加修改器，这里巫医要加一个延迟弹射的效果
	target:AddNewModifier(
		self:GetCaster(), -- player source
		self, -- ability source
		"modifier_witch_doctor_death_ward_lua_effect_thinker", -- modifier name
		{
			key = kv.key,
			duration = bounce_delay,
		} -- kv
	)
end

--------------------------------------------------------------------------------
-- Graphics & Effects
-- 播放追踪特效
function witch_doctor_death_ward_lua:PlayProjectile( info )
	local tracker = info.Target:AddNewModifier(
		info.Source, -- player source
		self, -- ability source
		"modifier_generic_tracking_projectile", -- modifier name
		-- 持续4秒
		{ duration = 4 } -- kv
	)
	tracker:PlayTrackingProjectile( info )
	
	info.EffectName = nil
	if not info.ExtraData then info.ExtraData = {} end
	info.ExtraData.tracker = tempTable:AddATValue( tracker )

	return info
end

function witch_doctor_death_ward_lua:StopProjectile( kv )
	local tracker = tempTable:RetATValue( kv.tracker )
	if tracker and not tracker:IsNull() then tracker:Destroy() end
end