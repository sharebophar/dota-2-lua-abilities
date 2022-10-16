modifier_witch_doctor_death_ward_lua_effect_thinker = class({})
local tempTable = require( "util/tempTable" )
require("libraries/table")

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_death_ward_lua_effect_thinker:IsHidden()
	return false
end

function modifier_witch_doctor_death_ward_lua_effect_thinker:IsPurgable()
	return false
end

function modifier_witch_doctor_death_ward_lua_effect_thinker:RemoveOnDeath()
	return false
end

function modifier_witch_doctor_death_ward_lua_effect_thinker:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_death_ward_lua_effect_thinker:OnCreated( kv )
	-- 应该是加上去就弹射
	if IsServer() then
		local castTable = tempTable:GetATValue( kv.key )
		-- find enemies
		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),	-- int, your team number
			self:GetParent():GetOrigin(),	-- point, center point
			nil,	-- handle, cacheUnit. (not known)
			castTable.jump_range,	-- float, radius. or use FIND_UNITS_EVERYWHERE
			DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
			DOTA_UNIT_TARGET_HERO,	-- int, type filter
			DOTA_UNIT_TARGET_FLAG_NONE,	-- int, flag filter
			FIND_CLOSEST,	-- int, order filter
			false	-- bool, can grow cache
		)

		-- get random enemy
		local target = nil
		for _,enemy in pairs(enemies) do
			if enemy~=self:GetParent() and not table.contains(castTable.bounced_targets,enemy) then
				target = enemy
				break
			end
		end

		if not target then
			-- stop bouncing
			castTable = tempTable:RetATValue( kv.key )
			return
		end

		-- 标记已经被弹射过的目标
		table.insert(castTable.bounced_targets,target)
		-- bounce to enemy
		castTable.projectile.Target = target
		castTable.projectile.Source = self:GetParent()
		castTable.projectile.EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf"
		-- castTable.projectile.EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_cask.vpcf"
		castTable.projectile = self:GetAbility():PlayProjectile( castTable.projectile )
		ProjectileManager:CreateTrackingProjectile( castTable.projectile )
	end
end

function modifier_witch_doctor_death_ward_lua_effect_thinker:OnRefresh( kv )
	
end

function modifier_witch_doctor_death_ward_lua_effect_thinker:OnDestroy( kv )
	
end
