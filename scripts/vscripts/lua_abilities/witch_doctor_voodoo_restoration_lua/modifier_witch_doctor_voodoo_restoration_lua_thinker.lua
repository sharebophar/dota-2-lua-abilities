-- Created by Elfansoer
--[[
-- 巫毒治疗术
]]
--------------------------------------------------------------------------------
modifier_witch_doctor_voodoo_restoration_lua_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_voodoo_restoration_lua_thinker:IsHidden()
	return false
end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:IsDebuff()
	return false
end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:IsPurgable()
	return false
end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_voodoo_restoration_lua_thinker:OnCreated( kv )
    if not IsServer() then return end
	-- 光环的粘滞效果，创建的0.33秒后造成一次治疗或伤害
    local caster = self:GetAbility():GetCaster()
    local target = self:GetParent()

    --target:SetContextThink("AffactLater",function()
       -- if target and target:IsAlive() then
            if caster:GetTeamNumber() == target:GetTeamNumber() then
                -- 救己
                target:Heal( kv.heal, self:GetAbility() )
            else
                -- 伤敌
                -- 由于kv不能直接将table传过来，这里需要重新构建
                local damageTable = 
                {
			        victim = target,
			        attacker = caster,
                    damage = kv.damage,
                    damage_type = kv.damage_type,
                    ability = self:GetAbility()
                }
				ApplyDamage(damageTable)
            end
       -- end
    --end,0)
    -- 为什么第三个参数有几率返回void ?
    -- end,kv.affact_interval)
	print("kv.affact_interval:",kv.affact_interval)
end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:OnRefresh( kv )
	-- references

end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:OnRemoved()
end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:OnDestroy()
    
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_witch_doctor_voodoo_restoration_lua_thinker:DeclareFunctions()
	
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_witch_doctor_voodoo_restoration_lua_thinker:GetEffectName()
	return "particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_flame_a.vpcf"
    -- return "particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration_aura.vpcf"
end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:PlayEffects(target )
	
end