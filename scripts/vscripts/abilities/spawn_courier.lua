function spawn_courier(keys)
    local caster = keys.caster
    local team = caster:GetTeam()
    local player = caster:GetPlayerOwner()
    local playerID = caster:GetPlayerOwnerID()
    CreateUnitByNameAsync(
        "npc_dota_courier_creature",
        caster:GetAbsOrigin(),
        true,
        nil,
        nil,
        team,
        function(hUnit)
            table.insert(GameRules.herodemo.m_tAlliesList, hUnit)
            hUnit:SetOwner(player)
            hUnit:SetControllableByPlayer(playerID, false)
            hUnit:AddNewModifier(hUnit, nil, "no_health_bar", nil)
            local ability_count = hUnit:GetAbilityCount()
            for i = 0, ability_count - 1 do
                local ability = hUnit:GetAbilityByIndex(i)
                if ability then
                    ability:SetLevel(ability:GetMaxLevel())
                end
            end
            Wearable:UICacheAvailableCouriers()
            FindClearSpaceForUnit(hUnit, caster:GetAbsOrigin(), false)
            hUnit:Hold()
            hUnit:SetIdleAcquire(false)
            hUnit:SetAcquisitionRange(0)
        end
    )
end
