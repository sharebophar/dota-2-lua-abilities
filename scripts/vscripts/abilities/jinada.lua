--[[Jinada
	Author: Pizzalol
	Date: 1.1.2015.]]
function Jinada(keys)
    local ability = keys.ability
    local level = ability:GetLevel() - 1
    local cooldown = ability:GetCooldown(level)
    local caster = keys.caster
    local modifierName = "modifier_bounty_hunter_jinada"

    ability:StartCooldown(cooldown)

    caster:RemoveModifierByName(modifierName)

    Timers:CreateTimer(
        cooldown,
        function()
            ability:ApplyDataDrivenModifier(caster, caster, modifierName, {})
        end
    )
end

function JinadaAddParticle(keys)
    local caster = keys.caster
    local point = keys.target_points[1]
    local ability = keys.ability

    local p_name1 = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_hand_r.vpcf"
    local p1 = ParticleManager:CreateParticle(p_name1, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(
        p1,
        0,
        caster,
        PATTACH_POINT_FOLLOW,
        "attach_weapon1",
        caster:GetAbsOrigin(),
        true
    )
    caster.jinada_p1 = p1

    local p_name2 = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_hand_l.vpcf"
    local p2 = ParticleManager:CreateParticle(p_name2, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(
        p2,
        0,
        caster,
        PATTACH_POINT_FOLLOW,
        "attach_weapon2",
        caster:GetAbsOrigin(),
        true
    )
    caster.jinada_p2 = p2
end


function JinadaRemoveParticle(keys)
    local ability = keys.ability
    local caster = keys.caster
    
    if caster.jinada_p1 then
        ParticleManager:DestroyParticle(caster.jinada_p1, false)
        ParticleManager:ReleaseParticleIndex(caster.jinada_p1)
        caster.jinada_p1 = nil
    end
    if caster.jinada_p2 then
        ParticleManager:DestroyParticle(caster.jinada_p2, false)
        ParticleManager:ReleaseParticleIndex(caster.jinada_p2)
        caster.jinada_p2 = nil
    end
end

function JinadaAnimation( keys )
    local caster = keys.caster
    caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK_EVENT, 1.5)
end