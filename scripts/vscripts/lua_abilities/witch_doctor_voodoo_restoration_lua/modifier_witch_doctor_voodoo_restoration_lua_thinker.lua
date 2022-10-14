-- Created by Elfansoer
--[[
-- 巫毒治疗术
]]
--------------------------------------------------------------------------------
modifier_witch_doctor_voodoo_restoration_lua_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_witch_doctor_voodoo_restoration_lua_thinker:IsHidden()
    -- 每跳的效果要隐藏，和游戏保持一致
	return true
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

function modifier_witch_doctor_voodoo_restoration_lua_thinker:DamageOrHeal(kv)
    if not IsServer() then return end
    local caster = self:GetAbility():GetCaster()
    local target = self:GetParent()
    if target and target:IsAlive() then
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
    end
	-- print("kv.affact_interval:",kv.affact_interval)
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_witch_doctor_voodoo_restoration_lua_thinker:OnCreated( kv )
    -- self:DamageOrHeal(kv)
    -- 创建时不造成伤害，0.33秒的第二次后才会造成伤害，所以伤害逻辑只在OnRefresh中
end

function modifier_witch_doctor_voodoo_restoration_lua_thinker:OnRefresh( kv )
	-- references
    self:DamageOrHeal(kv)
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