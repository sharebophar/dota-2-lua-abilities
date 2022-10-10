function spawn_ward_observer(keys)
    spawn_ward( keys, "npc_dota_observer_wards" )
end

function spawn_ward_sentry(keys)
    spawn_ward( keys, "npc_dota_sentry_wards" )
end

function spawn_ward( keys, ward_name )
    PrintTable(keys)
    local caster = keys.caster
    local point = keys.target_points[1]
    local team = caster:GetTeam()
    local player = caster:GetPlayerOwner()
    local playerID = caster:GetPlayerOwnerID()
    local hero = player:GetAssignedHero()
    CreateUnitByNameAsync(
        ward_name,
        point,
        true,
        nil,
        nil,
        team,
        function(hUnit)
            table.insert(GameRules.herodemo.m_tAlliesList, hUnit)
            hUnit:SetOwner(hero)
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
            -- FindClearSpaceForUnit(hUnit, point, false)
            hUnit:Hold()
            hUnit:SetIdleAcquire(false)
            hUnit:SetAcquisitionRange(0)
        end
    )
end
