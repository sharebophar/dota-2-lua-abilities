witch_doctor_paralyzing_cask_lua = class({})
LinkLuaModifier( "modifier_generic_stunned_lua", "lua_abilities/generic/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_witch_doctor_paralyzing_cask_lua", "lua_abilities/witch_doctor_paralyzing_cask_lua/modifier_witch_doctor_paralyzing_cask_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_witch_doctor_paralyzing_cask_lua_thinker", "lua_abilities/witch_doctor_paralyzing_cask_lua/modifier_witch_doctor_paralyzing_cask_lua_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_tracking_projectile", "lua_abilities/generic/modifier_generic_tracking_projectile", LUA_MODIFIER_MOTION_NONE )
local tempTable = require( "util/tempTable" )

--------------------------------------------------------------------------------
-- Custom KV
function witch_doctor_paralyzing_cask_lua:GetCastRange( vLocation, hTarget )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "cast_range_scepter" )
	end

	return self.BaseClass.GetCastRange( self, vLocation, hTarget )
end

function witch_doctor_paralyzing_cask_lua:GetCooldown( level )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "cooldown_scepter" )
	end

	return self.BaseClass.GetCooldown( self, level )
end

--------------------------------------------------------------------------------
-- Ability Start
function witch_doctor_paralyzing_cask_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- 记录一个弹跳次数
	self.bounce_times = 0
	-- load data
	local base_damage = self:GetSpecialValueFor("base_damage")
	
	--[[
	// 有蓝杖效果的情况下读取蓝杖的伤害，这里用不到，后面在巫医大招时用
	local scepter = false
	if caster:HasScepter() then
		damage = self:GetSpecialValueFor("damage_scepter")
		scepter = true
	end
	]]
	-- store data
	local castTable = {
		base_damage = base_damage,
		scepter = scepter,
		jump = 0,
		jumps = self:GetSpecialValueFor("bounces"),  -- 这个读取次数得验证一下
		jump_range = self:GetSpecialValueFor("bounce_range"),
		--as_slow = self:GetSpecialValueFor("slow_attack_speed"),
		--ms_slow = self:GetSpecialValueFor("slow_movement_speed"),
		creep_damage_pct = self:GetSpecialValueFor("creep_damage_pct"),	-- 小怪伤害加成
		bounce_bonus_damage = self:GetSpecialValueFor("bounce_bonus_damage"),
		creep_duration = self:GetSpecialValueFor("creep_duration"),		-- 小怪眩晕时间
		hero_duration = self:GetSpecialValueFor("hero_duration"),		-- 英雄眩晕时间
	}
	local key = tempTable:AddATValue( castTable )

	-- load projectile 播放的特效
	-- local projectile_name = "particles/econ/items/lich/lich_ti8_immortal_arms/lich_ti8_chain_frost.vpcf"
	local projectile_name = "particles/units/heroes/hero_witchdoctor/witchdoctor_cask.vpcf"
	-- local projectile_name = "particles/econ/items/witch_doctor/wd_2021_cache/wd_2021_cache_death_ward.vpcf"
	
	local projectile_speed = self:GetSpecialValueFor("speed")
	-- 投射物提供的视野范围，事实证明，麻痹药剂是不考虑视野的，只要目标在范围内，即使没有视野依然可以弹射。麻痹药剂也不会为友方玩家提供视野
	-- local projectile_vision = self:GetSpecialValueFor("bounce_range")
	-- 这是个可选值，不填会由默认值填充

	local projectile_info = {
		Target = target,
		Source = caster,
		Ability = self,	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = false,                           -- Optional
	
		bVisibleToEnemies = true,                         -- Optional
		--bProvidesVision = true,                           -- Optional
		bProvidesVision = false,  
		-- iVisionRadius = projectile_vision,                 -- Optional
		-- iVisionTeamNumber = caster:GetTeamNumber(),        -- Optional
		ExtraData = {
			key = key,
		}
	}
	-- 播放起手的那个特效
	projectile_info = self:PlayProjectile( projectile_info )
	castTable.projectile = projectile_info
	-- 创建弹射特效
	ProjectileManager:CreateTrackingProjectile( castTable.projectile )

	-- play effects 播放的音效
	-- local sound_cast = "Hero_Lich.ChainFrost"
	-- 引用在 game_sounds_witchdoctor.vsndevts 中找到
	local sound_cast = "Hero_WitchDoctor.Paralyzing_Cask_Cast"
	EmitSoundOn( sound_cast, caster )
end

--------------------------------------------------------------------------------
-- Projectile 特效击中事件
function witch_doctor_paralyzing_cask_lua:OnProjectileHit_ExtraData( target, location, kv )
	self:StopProjectile( kv )
	self.bounce_times = self.bounce_times + 1
	-- load data
	local bounce_delay = self:GetSpecialValueFor("bounce_delay") -- 巫医这里走的配置
	local castTable = tempTable:GetATValue( kv.key )
	local damage = castTable.base_damage + self.bounce_times * castTable.bounce_bonus_damage

	-- bounce thinker
	-- 弹射命中时添加修改器，这里巫医要加一个延迟弹射的效果
	target:AddNewModifier(
		self:GetCaster(), -- player source
		self, -- ability source
		"modifier_witch_doctor_paralyzing_cask_lua_thinker", -- modifier name
		{
			key = kv.key,
			duration = bounce_delay,
		} -- kv
	)

	-- apply damage and slow
	-- 如果目标不是魔法免疫且不是无敌的，造成伤害
	if (not target:IsMagicImmune()) and (not target:IsInvulnerable()) then
		local stun_duration = target:IsCreep() and castTable.creep_duration or castTable.hero_duration
		-- 为目标添加一个麻痹效果
		local stun_modifier = target:AddNewModifier(
			self:GetCaster(), -- player source
			self, -- ability source
			-- 使用通用眩晕逻辑
			"modifier_generic_stunned_lua",
			{
				-- 小兵和英雄的眩晕时间按配置区分
				duration = stun_duration,
			} -- kv
		)

		-- 造成伤害后可能导致目标死亡，造成的目标丢失，从而生成的修改器为空，所以需要判空
		if stun_modifier then
			-- 这个眩晕效果是公共效果，包括冰女的冰封禁制也是使用这个逻辑，但表现需要各自的逻辑额外添加
			local stun_effect = ParticleManager:CreateParticle(stun_modifier:GetEffectName(), PATTACH_OVERHEAD_FOLLOW, target )
			self:SetContextThink(DoUniqueString("DestroyStun"),function()
				ParticleManager:DestroyParticle(stun_effect,false)
				ParticleManager:ReleaseParticleIndex(stun_effect)
			end,stun_duration)
		end

		-- 生效次序是先麻痹，再伤害
		local damageTable = {
			victim = target,
			attacker = self:GetCaster(),
			damage = target:IsCreep() and  (damage * castTable.creep_damage_pct/100.0) or damage , -- 非英雄单位伤害加成
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self, --Optional.
		}
		ApplyDamage(damageTable)
	end

	-- play effects播放击中音效
	--[[
	local sound_target = "Hero_Lich.ChainFrostImpact.Creep"
	if target:IsConsideredHero() then
		sound_target = "Hero_Lich.ChainFrostImpact.Hero"
	end
	]]
	-- 巫妖的弹射音效对怪和人没有区别
	local sound_target = "Hero_WitchDoctor.Paralyzing_Cask_Bounce"
	EmitSoundOn( sound_target, target )
end

--------------------------------------------------------------------------------
-- Graphics & Effects
-- 播放追踪特效
function witch_doctor_paralyzing_cask_lua:PlayProjectile( info )
	local tracker = info.Target:AddNewModifier(
		info.Source, -- player source
		self, -- ability source
		"modifier_generic_tracking_projectile", -- modifier name
		-- 持续4秒？
		{ duration = 4 } -- kv
	)
	tracker:PlayTrackingProjectile( info )
	
	info.EffectName = nil
	if not info.ExtraData then info.ExtraData = {} end
	info.ExtraData.tracker = tempTable:AddATValue( tracker )

	return info
end

function witch_doctor_paralyzing_cask_lua:StopProjectile( kv )
	local tracker = tempTable:RetATValue( kv.tracker )
	if tracker and not tracker:IsNull() then tracker:Destroy() end
end