function DecayParticle( keys )
    local caster = keys.caster
    local point = keys.target_points[1]
    local ability = keys.ability

    local p_name = "particles/units/heroes/hero_undying/undying_decay.vpcf"
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() -1))
    local p = ParticleManager:CreateParticle(p_name, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(p, 0, point)
    ParticleManager:SetParticleControl(p, 1, Vector(radius, 1, 1))
    ParticleManager:SetParticleControlEnt(
        p,
        2,
        caster,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        caster:GetAbsOrigin(),
        true
    )

    local sound = "Hero_Undying.Decay.Cast"                      
    StartSoundEventFromPositionReliable(sound, point)

    local p_name2 = "particles/units/heroes/hero_undying/undying_decay_cast.vpcf"
    local p2 = ParticleManager:CreateParticle(p_name2, PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(p2, 0, caster:GetAbsOrigin())
end