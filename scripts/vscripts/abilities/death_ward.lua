--[[Author: YOLOSPAGHETTI
	Date: March 15, 2016
	Creates the death ward]]
function CreateWard(keys)
    local caster = keys.caster
    local ability = keys.ability
    local position = ability:GetCursorPosition()

    -- Creates the death ward (There is no way to control the default ward, so this is a custom one)
    caster.death_ward =
        CreateUnitByName("npc_dota_witch_doctor_death_ward_custom", position, true, caster, caster, caster:GetTeam())
    caster.death_ward:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    caster.death_ward:SetOwner(caster)

    local sModel = caster.summon_model["npc_dota_witch_doctor_death_ward"]
    if sModel then
        Timers:CreateTimer(
            0.034,
            function()
                if not (IsValidEntity(caster.death_ward) and caster.death_ward:IsAlive()) then
                    return
                end
                caster.death_ward:SetOriginalModel(sModel)
                caster.death_ward:SetModel(sModel)
                if caster.summon_skin then
                    caster.death_ward:SetSkin(caster.summon_skin)
                end
                caster.death_ward:StartGesture(ACT_DOTA_SPAWN)
                Timers:CreateTimer(
                    0.7,
                    function(...)
                        if not (IsValidEntity(caster.death_ward) and caster.death_ward:IsAlive()) then
                            return
                        end
                        caster.death_ward:RemoveGesture(ACT_DOTA_SPAWN)
                        caster.death_ward:StartGesture(ACT_DOTA_IDLE)
                    end
                )
            end
        )
    end


    local radius = caster.death_ward:GetAcquisitionRange()
    local enemies =
        FindUnitsInRadius(
        caster:GetTeamNumber(),
        position,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    if enemies[1] then
        caster.death_ward:SetForceAttackTarget(enemies[1])
    end

    -- Applies the modifier (gives it damage, removes health bar, and makes it invulnerable)
    ability:ApplyDataDrivenModifier(caster, caster.death_ward, "modifier_death_ward_datadriven", {})

    local p_name1 = "particles/units/heroes/hero_witchdoctor/witchdoctor_deathward_glow_c.vpcf"
    local p1 = ParticleManager:CreateParticle(p_name1, PATTACH_CUSTOMORIGIN, caster.death_ward)

    local p_name2 = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_skull.vpcf"
    local p_name3 = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_cast_staff_fire.vpcf"

    local bRibbi = caster.Slots["summon"] and caster.Slots["summon"]["itemDef"] == "7380"
    if bRibbi then
        p_name2 = "particles/econ/items/witch_doctor/witch_doctor_ribbitar/witchdoctor_ribbitar_ward_skull.vpcf"
        p_name3 = "particles/econ/items/witch_doctor/witch_doctor_ribbitar/witchdoctor_ward_cast_staff_fire_ribbitar.vpcf"
        caster.death_ward:SetRangedProjectileName("particles/econ/items/witch_doctor/witch_doctor_ribbitar/witch_doctor_ribbitar_ward_attack.vpcf")
    end

    local p2 = ParticleManager:CreateParticle(p_name2, PATTACH_CUSTOMORIGIN, caster.death_ward)
    ParticleManager:SetParticleControlEnt(
        p2,
        0,
        caster.death_ward,
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        caster.death_ward:GetAbsOrigin(),
        true
    )

    caster.cast_stuff = ParticleManager:CreateParticle(p_name3, PATTACH_CUSTOMORIGIN, caster)
    if bRibbi and caster.prismatic then
        local sHexColor = Wearable.prismatics[caster.prismatic].hex_color
        local vColor = HexColor2RGBVector(sHexColor)
        ParticleManager:SetParticleControl(p2, 16, Vector(1, 0, 0))
        ParticleManager:SetParticleControl(p2, 15, vColor)
        ParticleManager:SetParticleControl(caster.cast_stuff, 16, Vector(1, 0, 0))
        ParticleManager:SetParticleControl(caster.cast_stuff, 15, vColor)
    end
end

--[[Author: YOLOSPAGHETTI
	Date: March 15, 2016
	Removes the death ward entity from the game and stops its sound]]
function DestroyWard(keys)
    local caster = keys.caster

    UTIL_Remove(caster.death_ward)
    StopSoundEvent(keys.sound, caster)
    if caster.cast_stuff then
        ParticleManager:DestroyParticle(caster.cast_stuff, false)
        ParticleManager:ReleaseParticleIndex(caster.cast_stuff)
        caster.cast_stuff = nil
    end
end
