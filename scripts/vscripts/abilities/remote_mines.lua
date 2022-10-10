function self_detonate(keys)
    local caster = keys.caster
    local ability = keys.ability
    local owner = caster:GetOwner()

    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() -1))

    local p_name = "particles/units/heroes/hero_techies/techies_remote_mines_detonate.vpcf"
    local sound = "Hero_Techies.RemoteMine.Detonate"
    if owner.Slots and owner.Slots["mount"] and owner.Slots["mount"]["itemDef"] == "6879" then
        p_name = "particles/econ/items/techies/techies_arcana/techies_remote_mines_detonate_arcana.vpcf"
        sound = "Hero_Techies.RemoteMine.Detonate.Arcana"
    end
    
    local location = caster:GetAbsOrigin()
    local p = ParticleManager:CreateParticle(p_name, PATTACH_CUSTOMORIGIN, owner)
    ParticleManager:SetParticleControl(p, 0, location)
    ParticleManager:SetParticleControl(p, 1, Vector(radius, radius, radius))
    
    if owner.prismatic then
        local sHexColor = Wearable.prismatics[owner.prismatic].hex_color
        local vColor = HexColor2RGBVector(sHexColor)
        ParticleManager:SetParticleControl(p, 16, Vector(1, 0, 0))
        ParticleManager:SetParticleControl(p, 15, vColor)
    end

    StartSoundEventFromPosition(sound, location)

    caster:ForceKill(false)
end

function focus_detonate(keys)
    print("focus_detonate")
    local caster = keys.caster
    local ability = keys.ability
    local position = ability:GetCursorPosition()

    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() -1))
    local mines =
        FindUnitsInRadius(
        caster:GetTeamNumber(),
        position,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_ALL,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    print(mines, #mines)
    local playerID = caster:GetPlayerOwnerID()
    for _, mine in pairs(mines) do
        local self_deto = mine:FindAbilityByName("techies_remote_mines_self_detonate")
        print(_, mine, mines, self_deto)
        if self_deto then
            mine:CastAbilityImmediately( self_deto, playerID )
        end
    end
end

function OnSpawn(keys)
    print("OnSpawn")
    local caster = keys.caster
    local ability = keys.ability
    local owner = caster:GetOwner()

    if owner.Slots and owner.Slots["mount"] and owner.Slots["arms"]["itemDef"] == "6908" then
        local p_name = "particles/econ/items/techies/techies_arcana/techies_remote_mine_arcana.vpcf"
        local p = ParticleManager:CreateParticle(p_name, PATTACH_CUSTOMORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(p, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)

        if owner.prismatic then
            local sHexColor = Wearable.prismatics[owner.prismatic].hex_color
            local vColor = HexColor2RGBVector(sHexColor)
            ParticleManager:SetParticleControl(p, 16, Vector(1, 0, 0))
            ParticleManager:SetParticleControl(p, 15, vColor)
        end
    end
end