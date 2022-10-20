function CHeroDemo:OnGameRulesStateChange()
    local nNewState = GameRules:State_Get()
    --print( "OnGameRulesStateChange: " .. nNewState )

    if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        print("OnGameRulesStateChange: Hero Selection")
    elseif nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
        print("OnGameRulesStateChange: Pre Game Selection")
        SendToServerConsole("dota_dev forcegamestart")
    elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        print("OnGameRulesStateChange: Game In Progress")
        -- Wearable:RequestParticles()
    end
end

function CHeroDemo:OnNPCSpawned(event)
    local spawnedUnit = EntIndexToHScript(event.entindex)

    if spawnedUnit:GetPlayerOwnerID() == 0 and spawnedUnit:IsRealHero() and not spawnedUnit:IsClone() then
        --print( "spawnedUnit is player's hero" )
        local hPlayerHero = spawnedUnit
        hPlayerHero:SetContextThink(
            "self:Think_InitializePlayerHero",
            function()
                return self:Think_InitializePlayerHero(hPlayerHero)
            end,
            0
        )
    end

    if spawnedUnit:GetUnitName() == "npc_dota_neutral_caster" then
        --print( "Neutral Caster spawned" )
        spawnedUnit:SetContextThink(
            "self:Think_InitializeNeutralCaster",
            function()
                return self:Think_InitializeNeutralCaster(spawnedUnit)
            end,
            0
        )
    end

    -- 服装师
    if spawnedUnit:GetUnitName() == "npc_dota_hero_witch_doctor" or spawnedUnit:GetUnitName() == "npc_dota_hero_phoenix" then
        spawnedUnit:SetAbilityPoints(30)
        --spawnedUnit:AddNewModifier(spawnedUnit, nil, "dresser", nil)
        --spawnedUnit:FindAbilityByName("day"):SetLevel(1)
        --spawnedUnit:FindAbilityByName("night"):SetLevel(1)
        for i=1,30 do
            spawnedUnit:HeroLevelUp(false)
        end
        spawnedUnit:UpgradeAbility(spawnedUnit:GetAbilityByIndex(0))
        spawnedUnit:UpgradeAbility(spawnedUnit:GetAbilityByIndex(1))
        spawnedUnit:UpgradeAbility(spawnedUnit:GetAbilityByIndex(2))
        spawnedUnit:UpgradeAbility(spawnedUnit:GetAbilityByIndex(3))
    end

    if
        (spawnedUnit:GetClassname() == "npc_dota_creep_lane" or spawnedUnit:GetClassname() == "npc_dota_creep_siege") and
            self.m_bNoCreep
     then
        spawnedUnit:RemoveSelf()
    end

    -- 换装英雄
    if string.sub(spawnedUnit:GetUnitName(), 1, 14) == "npc_dota_unit_" then
        ActivityModifier:AddActivityModifierThink(spawnedUnit)
        if self.m_bInvulnerabilityEnabled then
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "lm_take_no_damage", nil)
        end
        local ability_count = spawnedUnit:GetAbilityCount()
        for i = 0, ability_count - 1 do
            local ability = spawnedUnit:GetAbilityByIndex(i)
            if ability then
                ability:SetLevel(ability:GetMaxLevel())
            end
        end

        if string.sub(spawnedUnit:GetUnitName(), 1, 21) == "npc_dota_unit_invoker" then
            StartAnimation(spawnedUnit, {duration = -1, activity = ACT_DOTA_CONSTANT_LAYER, rate = 1.0})
        end
    end

    -- 召唤单位模型
    local hOwner = spawnedUnit:GetOwner()
    if hOwner and hOwner.summon_model then
        local sUnitName = spawnedUnit:GetUnitName()
        local sUnitClassName = spawnedUnit:GetClassname()
        local sUnitNameNoNum = string.remove_num(sUnitName)
        local sModel =
            hOwner.summon_model[sUnitName] or hOwner.summon_model[sUnitClassName] or hOwner.summon_model[sUnitNameNoNum]
        if sModel then
            Timers:CreateTimer(
                0.034,
                function()
                    if not (IsValidEntity(spawnedUnit) and spawnedUnit:IsAlive()) then
                        return
                    end
                    spawnedUnit:SetOriginalModel(sModel)
                    spawnedUnit:SetModel(sModel)
                    if hOwner.summon_skin then
                        spawnedUnit:SetSkin(hOwner.summon_skin)
                    end
                    if spawnedUnit:HasMovementCapability() then
                        spawnedUnit:MoveToPosition(spawnedUnit:GetAbsOrigin())
                    else
                        spawnedUnit:StartGesture(ACT_DOTA_SPAWN)
                        Timers:CreateTimer(
                            0.7,
                            function(...)
                                if not (IsValidEntity(spawnedUnit) and spawnedUnit:IsAlive()) then
                                    return
                                end
                                spawnedUnit:RemoveGesture(ACT_DOTA_SPAWN)
                                spawnedUnit:StartGesture(ACT_DOTA_IDLE)
                            end
                        )
                    end
                end
            )
        end
    end

    -- 信使
    if spawnedUnit:GetUnitName() == "npc_dota_courier_creature" then
        local ability_count = spawnedUnit:GetAbilityCount()
        for i = 0, ability_count - 1 do
            local ability = spawnedUnit:GetAbilityByIndex(i)
            if ability then
                ability:SetLevel(ability:GetMaxLevel())
            end
        end
        Wearable:UICacheAvailableCouriers()
        FindClearSpaceForUnit(spawnedUnit, spawnedUnit:GetAbsOrigin(), true)
    end
end

function CHeroDemo:Think_InitializePlayerHero(hPlayerHero)
    if not hPlayerHero then
        return 0.1
    end

    if self.m_bPlayerDataCaptured == false then
        if hPlayerHero:GetUnitName() == self.m_sHeroSelection then
            local nPlayerID = hPlayerHero:GetPlayerOwnerID()
            PlayerResource:ModifyGold(nPlayerID, 99999, true, 0)
            self.m_bPlayerDataCaptured = true
        end
    end

    if self.m_bInvulnerabilityEnabled then
        local hAllPlayerUnits = {}
        hAllPlayerUnits = hPlayerHero:GetAdditionalOwnedUnits()
        hAllPlayerUnits[#hAllPlayerUnits + 1] = hPlayerHero

        for _, hUnit in pairs(hAllPlayerUnits) do
            hUnit:AddNewModifier(hPlayerHero, nil, "lm_take_no_damage", nil)
        end
    end

    FindClearSpaceForUnit(hPlayerHero, hPlayerHero:GetAbsOrigin() + Vector(-200, 200, 0), false)

    return
end

function CHeroDemo:Think_InitializeNeutralCaster(neutralCaster)
    if not neutralCaster then
        return 0.1
    end

    --print( "neutralCaster:AddAbility( \"la_spawn_enemy_at_target\" )" )
    neutralCaster:AddAbility("la_spawn_enemy_at_target")
    return
end

function CHeroDemo:OnItemPurchased(event)
    local hBuyer = PlayerResource:GetPlayer(event.PlayerID)
    local hBuyerHero = hBuyer:GetAssignedHero()
    hBuyerHero:ModifyGold(event.itemcost, true, 0)
end

function CHeroDemo:OnNPCReplaced(event)
    local sNewHeroName = PlayerResource:GetSelectedHeroName(event.new_entindex)
    --print( "sNewHeroName == " .. sNewHeroName ) -- we fail to get in here
    self:BroadcastMsg("Changed hero to " .. sNewHeroName)
end

function CHeroDemo:OnWelcomePanelDismissed(event)
    --print( "Entering CHeroDemo:OnWelcomePanelDismissed( event )" )
end

function CHeroDemo:OnRefreshButtonPressed(eventSourceIndex)
    SendToServerConsole("dota_dev hero_refresh")
    local creatures = Entities:FindAllByClassname("npc_dota_creature")
    for k, creature in pairs(creatures) do
        local ability_count = creature:GetAbilityCount()
        for i = 0, ability_count - 1 do
            local ability = creature:GetAbilityByIndex(i)
            if ability and (not ability:IsCooldownReady()) then
                ability:EndCooldown()
            end
        end
        for i = 0, 8 do
            local item = creature:GetItemInSlot(i)
            if item and (not item:IsCooldownReady()) then
                item:EndCooldown()
            end
        end
        creature:SetHealth(creature:GetMaxHealth())
        creature:SetMana(creature:GetMaxMana())
    end
    self:BroadcastMsg("#Refresh_Msg")
end

function CHeroDemo:OnLevelUpButtonPressed(eventSourceIndex)
    SendToServerConsole("dota_dev hero_level 1")
    self:BroadcastMsg("#LevelUp_Msg")
end

function CHeroDemo:OnMaxLevelButtonPressed(eventSourceIndex, data)
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    hPlayerHero:AddExperience(32400, false, false) -- for some reason maxing your level this way fixes the bad interaction with OnHeroReplaced
    --while hPlayerHero:GetLevel() < 25 do
    --hPlayerHero:HeroLevelUp( false )
    --end

    for i = 0, DOTA_MAX_ABILITIES - 1 do
        local hAbility = hPlayerHero:GetAbilityByIndex(i)
        if
            hAbility and hAbility:CanAbilityBeUpgraded() == ABILITY_CAN_BE_UPGRADED and not hAbility:IsHidden() and
                not hAbility:IsAttributeBonus()
         then
            while hAbility:GetLevel() < hAbility:GetMaxLevel() do
                hPlayerHero:UpgradeAbility(hAbility)
            end
        end
    end

    hPlayerHero:SetAbilityPoints(4)
    self:BroadcastMsg("#MaxLevel_Msg")
end

function CHeroDemo:OnFreeSpellsButtonPressed(eventSourceIndex)
    SendToServerConsole("toggle dota_ability_debug")
    if self.m_bFreeSpellsEnabled == false then
        self.m_bFreeSpellsEnabled = true
        SendToServerConsole("dota_dev hero_refresh")
        local creatures = Entities:FindAllByClassname("npc_dota_creature")
        for k, creature in pairs(creatures) do
            local ability_count = creature:GetAbilityCount()
            for i = 0, ability_count - 1 do
                local ability = creature:GetAbilityByIndex(i)
                if ability and (not ability:IsCooldownReady()) then
                    ability:EndCooldown()
                end
            end
            for i = 0, 8 do
                local item = creature:GetItemInSlot(i)
                if item and (not item:IsCooldownReady()) then
                    item:EndCooldown()
                end
            end
            creature:SetMana(creature:GetMaxMana())
        end
        self:BroadcastMsg("#FreeSpellsOn_Msg")
    elseif self.m_bFreeSpellsEnabled == true then
        self.m_bFreeSpellsEnabled = false
        self:BroadcastMsg("#FreeSpellsOff_Msg")
    end
end

function CHeroDemo:OnNoCreepButtonPressed(eventSourceIndex)
    if self.m_bNoCreep == false then
        self.m_bNoCreep = true
        local creeps = Entities:FindAllByClassname("npc_dota_creep_lane")
        for k, creep in pairs(creeps) do
            creep:RemoveSelf()
        end
        local sieges = Entities:FindAllByClassname("npc_dota_creep_siege")
        for k, siege in pairs(sieges) do
            siege:RemoveSelf()
        end
    elseif self.m_bNoCreep == true then
        self.m_bNoCreep = false
    end
end

function CHeroDemo:ToggleHideTree(eventSourceIndex)
    print("ToggleHideTree", self.bHideTree)
    if self.bHideTree == false then
        self.bHideTree = true
        local trees = GridNav:GetAllTreesAroundPoint(Vector(0, 0, 0), 99999, false);
        for k, tree in pairs(trees) do
            tree:CutDownRegrowAfter(-1,-1)
        end
    elseif self.bHideTree == true then
        self.bHideTree = false
        GridNav:RegrowAllTrees()
    end
end

function CHeroDemo:ToggleHideBuilding(eventSourceIndex)
    print("ToggleHideBuilding", self.bHideBuilding)
    if self.bHideBuilding == false then
        self.bHideBuilding = true
        local buildings = Entities:FindAllInSphere(Vector(0, 0, 0), 99999)
        for k, building in pairs(buildings) do
            if building.IsBuilding and building:IsBuilding() then
                building:AddEffects(EF_NODRAW)
            end
        end
    elseif self.bHideBuilding == true then
        self.bHideBuilding = false
        local buildings = Entities:FindAllInSphere(Vector(0, 0, 0), 99999)
        for k, building in pairs(buildings) do
            if building.IsBuilding and building:IsBuilding() then
                building:RemoveEffects(EF_NODRAW)
            end
        end
    end
end

function CHeroDemo:OnInvulnerabilityButtonPressed(eventSourceIndex, data)
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    local hAllPlayerUnits = {}
    hAllPlayerUnits = hPlayerHero:GetAdditionalOwnedUnits()
    hAllPlayerUnits[#hAllPlayerUnits + 1] = hPlayerHero

    local creatures = Entities:FindAllByClassname("npc_dota_creature")

    if self.m_bInvulnerabilityEnabled == false then
        for _, hUnit in pairs(hAllPlayerUnits) do
            hUnit:AddNewModifier(hPlayerHero, nil, "lm_take_no_damage", nil)
        end
        for _, hUnit in pairs(creatures) do
            if hUnit:GetPlayerOwner() == PlayerResource:GetPlayer(data.PlayerID) then
                hUnit:AddNewModifier(hPlayerHero, nil, "lm_take_no_damage", nil)
            end
        end
        self.m_bInvulnerabilityEnabled = true
        self:BroadcastMsg("#InvulnerabilityOn_Msg")
    elseif self.m_bInvulnerabilityEnabled == true then
        for _, hUnit in pairs(hAllPlayerUnits) do
            hUnit:RemoveModifierByName("lm_take_no_damage")
        end
        for _, hUnit in pairs(creatures) do
            if hUnit:GetPlayerOwner() == PlayerResource:GetPlayer(data.PlayerID) then
                hUnit:RemoveModifierByName("lm_take_no_damage")
            end
        end
        self.m_bInvulnerabilityEnabled = false
        self:BroadcastMsg("#InvulnerabilityOff_Msg")
    end
end

function CHeroDemo:OnSpawnEnemyButtonPressed(eventSourceIndex, data)
    self.m_sHeroToSpawn = DOTAGameManager:GetHeroUnitNameByID(tonumber(data.sHeroID))

    if #self.m_tEnemiesList >= 100 then
        self:BroadcastMsg("#MaxEnemies_Msg")
        return
    end

    local hPlayer = PlayerResource:GetPlayer(data.PlayerID)
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    local hSelectedUnit = EntIndexToHScript(data.nSelectedUnit)

    CreateUnitByNameAsync(
        self.m_sHeroToSpawn,
        hSelectedUnit:GetAbsOrigin(),
        true,
        nil,
        nil,
        GetEnemyTeam(hPlayer:GetTeam()),
        function(hEnemy)
            table.insert(self.m_tEnemiesList, hEnemy)
            hEnemy:SetControllableByPlayer(data.PlayerID, false)
            hEnemy:SetRespawnPosition(hSelectedUnit:GetAbsOrigin())
            FindClearSpaceForUnit(hEnemy, hSelectedUnit:GetAbsOrigin(), false)
            hEnemy:Hold()
            hEnemy:SetIdleAcquire(false)
            hEnemy:SetAcquisitionRange(0)
            self:BroadcastMsg("#SpawnEnemy_Msg")
            CustomGameEventManager:Send_ServerToPlayer(hPlayer, "SelectAndLookUnit", {unit = hEnemy:GetEntityIndex()})
        end
    )
end

function CHeroDemo:OnLevelUpEnemyButtonPressed(eventSourceIndex)
    for k, v in pairs(self.m_tEnemiesList) do
        if IsValidEntity(self.m_tEnemiesList[k]) and self.m_tEnemiesList[k]:IsRealHero() then
            self.m_tEnemiesList[k]:HeroLevelUp(false)
        end
    end
    self:BroadcastMsg("#LevelUpEnemy_Msg")
end

function CHeroDemo:OnDummyTargetButtonPressed(eventSourceIndex, data)
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    table.insert(
        self.m_tEnemiesList,
        CreateUnitByName(
            "npc_dota_hero_target_dummy",
            hPlayerHero:GetAbsOrigin(),
            true,
            nil,
            nil,
            GetEnemyTeam(hPlayerHero:GetTeam())
        )
    )
    local hDummy = self.m_tEnemiesList[#self.m_tEnemiesList]
    hDummy:SetAbilityPoints(0)
    hDummy:SetControllableByPlayer(data.PlayerID, false)
    hDummy:Hold()
    hDummy:SetIdleAcquire(false)
    hDummy:SetAcquisitionRange(0)
    self:BroadcastMsg("#SpawnDummyTarget_Msg")
end

function CHeroDemo:OnRemoveSpawnedUnitsButtonPressed(eventSourceIndex)
    for k, v in pairs(self.m_tAlliesList) do
        self.m_tAlliesList[k]:Destroy()
        self.m_tAlliesList[k] = nil
    end
    for k, v in pairs(self.m_tEnemiesList) do
        self.m_tEnemiesList[k]:Destroy()
        self.m_tEnemiesList[k] = nil
    end

    self.m_nEnemiesCount = 0

    self:BroadcastMsg("#RemoveSpawnedUnits_Msg")
end

function CHeroDemo:OnLaneCreepsButtonPressed(eventSourceIndex)
    SendToServerConsole("toggle dota_creeps_no_spawning")
    if self.m_bCreepsEnabled == false then
        self.m_bCreepsEnabled = true
        self:BroadcastMsg("#LaneCreepsOn_Msg")
    elseif self.m_bCreepsEnabled == true then
        -- if we're disabling creep spawns, then also kill existing creep waves
        SendToServerConsole("dota_kill_creeps radiant")
        SendToServerConsole("dota_kill_creeps dire")
        self.m_bCreepsEnabled = false
        self:BroadcastMsg("#LaneCreepsOff_Msg")
    end
end

function CHeroDemo:OnChangeCosmeticsButtonPressed(eventSourceIndex)
    -- currently running the command directly in XML, should run it here if possible
    -- can use GetSelectedHeroID
end

function CHeroDemo:OnChangeHeroButtonPressed(eventSourceIndex, data)
    -- currently running the command directly in XML, should run it here if possible
    local nHeroID = PlayerResource:GetSelectedHeroID(data.PlayerID)
    print("PlayerResource:GetSelectedHeroID( data.PlayerID ) == " .. nHeroID)
end

function CHeroDemo:OnSpawnAllyButtonPressed(eventSourceIndex, data)

    -- 遗迹暖暖的创建友方带有外观数据
    --[[
    self.m_sHeroToSpawn = DOTAGameManager:GetHeroUnitNameByID(tonumber(data.sHeroID))

    -- if #self.m_tEnemiesList >= 100 then
    -- 	self:BroadcastMsg("#MaxEnemies_Msg")
    -- 	return
    -- end

    local unit_name = string.gsub(self.m_sHeroToSpawn, "npc_dota_hero", "npc_dota_unit")
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    local hPlayer = PlayerResource:GetPlayer(data.PlayerID)
    local hSelectedUnit = EntIndexToHScript(data.nSelectedUnit)

    local hNewWears = {}
    local sSpawnUnitName = unit_name
    if GameRules.herodemo.m_bRespawnWear then
        local hHeroSlots = Wearable.heroes[self.m_sHeroToSpawn]
        for sSlotName, hSlot in pairs(hHeroSlots) do
            if type(hSlot) == "table" and hSlot.DefaultItem then
                local itemDef = hSlot.DefaultItem
                hNewWears[sSlotName] = {
                    sItemDef = itemDef,
                    sStyle = "0"
                }
            end
        end

        sSpawnUnitName = Wearable:GetRepawnUnitName(self.m_sHeroToSpawn, hNewWears)
    end

    hSelectedUnit = hSelectedUnit or hPlayerHero
    
    CreateUnitByNameAsync(
        sSpawnUnitName,
        hSelectedUnit:GetAbsOrigin(),
        true,
        nil,
        nil,
        hPlayer:GetTeam(),
        function(hUnit)
            table.insert(self.m_tAlliesList, hUnit)
            hUnit:SetOwner(hPlayerHero)
            hUnit:SetControllableByPlayer(data.PlayerID, false)
            local position = hSelectedUnit:GetAbsOrigin() + hSelectedUnit:GetForwardVector() * 100
            FindClearSpaceForUnit(hUnit, position, false)
            hUnit:Hold()
            hUnit:SetIdleAcquire(false)
            hUnit:SetAcquisitionRange(0)
            hUnit:AddNewModifier(hUnit, nil, "no_health_bar", nil)
            self:BroadcastMsg("#SpawnAlly_Msg")
            hUnit.sHeroName = self.m_sHeroToSpawn
            hUnit.sUnitName = unit_name
            hUnit.nOriginID = hUnit:GetEntityIndex()
            if hUnit.sHeroName == "npc_dota_hero_tiny" then
                hUnit.Particles1 = {}
                hUnit.Particles2 = {}
                hUnit.Particles3 = {}
                hUnit.Particles4 = {}
            end
            if GameRules.herodemo.m_bRespawnWear then
                Wearable:WearAfterRespawn(hUnit, hNewWears)
            else
                Wearable:WearDefaults(hUnit)
            end
            if hUnit.sHeroName == "npc_dota_hero_tiny" then
                Wearable:SwitchTinyModel(hUnit, 1)
                ActivityModifier:AddWearableActivity(hUnit, "tree", -1)
            end
            CustomGameEventManager:Send_ServerToPlayer(hPlayer, "AllySpawned", {unit = hUnit:GetEntityIndex()})
            Http:GetVote(hUnit, data.PlayerID)
        end
    )

    Wearable:UICacheAvailableItems(unit_name)
]]
    -- 我们直接按照创建敌方英雄的方式创建
    self.m_sHeroToSpawn = DOTAGameManager:GetHeroUnitNameByID(tonumber(data.sHeroID))

    if #self.m_tAlliesList >= 100 then
        -- self:BroadcastMsg("#MaxEnemies_Msg")
        return
    end

    local hPlayer = PlayerResource:GetPlayer(data.PlayerID)
    local hPlayerHero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    local hSelectedUnit = EntIndexToHScript(data.nSelectedUnit)

    CreateUnitByNameAsync(
        self.m_sHeroToSpawn,
        hSelectedUnit:GetAbsOrigin(),
        true,
        nil,
        nil,
        hPlayer:GetTeam(),
        function(hUnit)
            table.insert(self.m_tAlliesList, hUnit)
            hUnit:SetOwner(hPlayerHero)
            hUnit:SetControllableByPlayer(data.PlayerID, false)
            hUnit:SetRespawnPosition(hSelectedUnit:GetAbsOrigin())
            FindClearSpaceForUnit(hUnit, hSelectedUnit:GetAbsOrigin(), false)
            hUnit:Hold()
            hUnit:SetIdleAcquire(false)
            hUnit:SetAcquisitionRange(0)
            hUnit.sHeroName = self.m_sHeroToSpawn
            self:BroadcastMsg("#SpawnAlly_Msg")
            CustomGameEventManager:Send_ServerToPlayer(hPlayer, "SelectAndLookUnit", {unit = hUnit:GetEntityIndex()})
        end
    )
end

function CHeroDemo:OnPauseButtonPressed(eventSourceIndex)
    SendToServerConsole("dota_pause")
end

function CHeroDemo:OnLeaveButtonPressed(eventSourceIndex)
    SendToServerConsole("disconnect")
end

function CHeroDemo:OnSwitchWearable(eventSourceIndex, data)
    -- print("OnSwitchWearable", data)
    local unit_id = data.unit
    local hUnit = EntIndexToHScript(unit_id)

    local sItemDef = data.itemDef
    local sItemStyle = data.itemStyle

    local sSlotName = Wearable:GetSlotName(sItemDef)

    Wearable:Wear(hUnit, sItemDef, sItemStyle)
end

function CHeroDemo:OnEntityKilled(data)
    local entindex_inflictor = data.entindex_inflictor
    local damagebits = data.damagebits
    local entindex_killed = data.entindex_killed
    local entindex_attacker = data.entindex_attacker

    local hEntityKilled = EntIndexToHScript(entindex_killed)
    if hEntityKilled.sHeroName then
        Timers:CreateTimer(
            5,
            function()
                local hPlayer = hEntityKilled:GetPlayerOwner()
                local nPlayerID = hPlayer:GetPlayerID()
                local hPlayerHero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
                hEntityKilled:RespawnUnit()
                local position = hPlayerHero:GetAbsOrigin() + hPlayerHero:GetForwardVector() * 100
                FindClearSpaceForUnit(hEntityKilled, position, false)
                hEntityKilled:Hold()
                hEntityKilled:SetIdleAcquire(false)
                hEntityKilled:SetAcquisitionRange(0)
            end
        )
    end
end

function CHeroDemo:SendToConsole(eventSourceIndex, data)
    local command = data.command
    SendToConsole(command)
    SendToServerConsole(command)
end

function CHeroDemo:SendToServerConsole(eventSourceIndex, data)
    local command = data.command
    SendToServerConsole(command)
end

function CHeroDemo:Taunt(data)
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)
    hUnit:StartGesture(ACT_DOTA_TAUNT)
end

function CHeroDemo:OnSwitchPrismatic(data)
    local nPlayerID = data.PlayerID
    if not _G.GemVips[nPlayerID] then
        return
    end
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)
    local sPrismaticName = data.prismaticName
    Wearable:SwitchPrismatic(hUnit, sPrismaticName)
end

function CHeroDemo:OnToggleEthereal(data)
    local nPlayerID = data.PlayerID
    if not _G.GemVips[nPlayerID] then
        return
    end
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)
    local sEtherealName = data.etherealName
    Wearable:ToggleEthereal(hUnit, sEtherealName)
end

function CHeroDemo:OnCopySelection(eventSourceIndex, data)
    local nEntityIndex = data.unit
    local hUnitOrigin = EntIndexToHScript(nEntityIndex)
    print("------------sHeroName",hUnitOrigin.sHeroName)
    if hUnitOrigin.sHeroName then
        local sUnitName = hUnitOrigin.sUnitName
        local hPlayer = hUnitOrigin:GetPlayerOwner()
        local nPlayerID = hPlayer:GetPlayerID()
        local hPlayerHero = PlayerResource:GetSelectedHeroEntity(nPlayerID)

        local sSpawnUnitName = sUnitName
        local hNewWears = {}
        if GameRules.herodemo.m_bRespawnWear then
            for sSlotNameOrigin, hWearOrigin in pairs(hUnitOrigin.Slots) do
                hNewWears[sSlotNameOrigin] = {
                    sItemDef = hWearOrigin["itemDef"],
                    sStyle = "0"
                }
            end
            sSpawnUnitName = Wearable:GetRepawnUnitName(hUnitOrigin.sHeroName, hNewWears)
        end

        print("------------sSpawnUnitName",sSpawnUnitName)

        CreateUnitByNameAsync(
            sSpawnUnitName,
            hUnitOrigin:GetAbsOrigin(),
            true,
            nil,
            nil,
            hPlayer:GetTeam(),
            function(hUnitNew)
                table.insert(self.m_tAlliesList, hUnitNew)
                hUnitNew:SetOwner(hPlayerHero)
                hUnitNew:SetControllableByPlayer(nPlayerID, false)
                local position = hUnitOrigin:GetAbsOrigin() + hUnitOrigin:GetForwardVector() * 100
                FindClearSpaceForUnit(hUnitNew, position, false)
                hUnitNew:Hold()
                hUnitNew:SetIdleAcquire(false)
                hUnitNew:SetAcquisitionRange(0)
                hUnitNew:AddNewModifier(hUnit, nil, "no_health_bar", nil)
                self:BroadcastMsg("#SpawnAlly_Msg")
                hUnitNew.sUnitName = hUnitOrigin.sUnitName
                hUnitNew.sHeroName = hUnitOrigin.sHeroName
                if hUnitNew.sHeroName == "npc_dota_hero_tiny" then
                    hUnitNew.Particles1 = {}
                    hUnitNew.Particles2 = {}
                    hUnitNew.Particles3 = {}
                    hUnitNew.Particles4 = {}
                end
                if GameRules.herodemo.m_bRespawnWear then
                    Wearable:WearAfterRespawn(hUnitNew, hNewWears)
                else
                    Wearable:WearLike(hUnitOrigin, hUnitNew)
                end
                if hUnitNew.sHeroName == "npc_dota_hero_tiny" then
                    Wearable:SwitchTinyModel(hUnitNew, 1)
                    ActivityModifier:AddWearableActivity(hUnitNew, "tree", -1)
                end
                CustomGameEventManager:Send_ServerToPlayer(hPlayer, "AllySpawned", {unit = hUnitNew:GetEntityIndex()})
            end
        )
    end
end

function CHeroDemo:OnRemoveSelection(eventSourceIndex, data)
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)

    if (not IsValidEntity(hUnit)) or (not hUnit:IsAlive()) then
        return
    end
    if hUnit.sHeroName then
        CustomNetTables:SetTableValue("hero_wearables", tostring(nEntityIndex), nil)
        CustomNetTables:SetTableValue("hero_prismatic", tostring(nEntityIndex), nil)
        CustomNetTables:SetTableValue("hero_ethereals", tostring(nEntityIndex), nil)
        CustomGameEventManager:Send_ServerToAllClients("AllyRemoved", {unit = nEntityIndex})
        hUnit:RemoveSelf()
    elseif hUnit:IsHero() and not hUnit:HasModifier("dresser") then
        hUnit:RemoveSelf()
    end
end

function CHeroDemo:OnResetGems(data)
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)
    local nPlayerID = data.PlayerID
    Wearable:ResetGems(hUnit)
end

function CHeroDemo:OnRespawnButtonPressed(eventSourceIndex)
    if self.m_bRespawnWear == false then
        self.m_bRespawnWear = true
    elseif self.m_bRespawnWear == true then
        self.m_bRespawnWear = false
    end
end

function CHeroDemo:On_dota_non_player_used_ability(data)
    if self.m_bFreeSpellsEnabled then
        local caster = EntIndexToHScript(data.caster_entindex)
        local ability = caster:FindAbilityByName(data.abilityname)
        if ability then
            ability:EndCooldown()
        end
        for i = 0, 8 do
            local item = caster:GetItemInSlot(i)
            if item and (not item:IsCooldownReady()) then
                item:EndCooldown()
            end
        end
        caster:SetMana(caster:GetMaxMana())
    end
end

local transform = {
    modifier_monkey_king_transform = 1,
    modifier_pangolier_gyroshell = 1,
    modifier_undying_flesh_golem = 1,
    modifier_phoenix_supernova_hiding = 1,
    modifier_tusk_snowball_movement = 1,
    modifier_lycan_shapeshift = 1,
    modifier_brewmaster_primal_split = 1,
    modifier_dragon_knight_dragon_form = 1,
    modifier_lone_druid_true_form = 1,
    modifier_terrorblade_metamorphosis = 1,
    modifier_puck_phase_shift = 1,
    modifier_obsidian_destroyer_astral_imprisonment_prison = 1,
    modifier_shadow_shaman_voodoo = 1,
    modifier_lion_voodoo = 1,
    modifier_sheepstick_debuff = 1,
    modifier_life_stealer_infest = 1
    -- modifier_life_stealer_infest_effect = 1,
}

-- 处理变身技能，暂不支持多重变身，如变身时被羊等等
function CHeroDemo:ModifierGainedFilter(data)
    local parent = EntIndexToHScript(data.entindex_parent_const)
    -- local caster = EntIndexToHScript(data.entindex_caster_const)
    local modifier_name = data.name_const
    local duration = data.duration
    -- if parent.sHeroName then
    --     print(modifier_name)
    -- end
    if parent.sHeroName then
        if transform[modifier_name] then
            Wearable:HideWearables(parent)
            if parent.transform_timer then
                Timers:RemoveTimer(parent.tramsform_timer)
                parent:SetModel(parent.hero_model_change.asset)
            end
            parent.tramsform_timer =
                Timers:CreateTimer(
                0.034,
                function()
                    if IsValidEntity(parent) and not parent:HasModifier(modifier_name) then
                        Wearable:ShowWearables(parent)
                    else
                        if
                            parent.hero_model_change and parent:GetModelName() == parent.hero_model_change.asset and
                                parent:GetModelName() ~= parent.hero_model_change.modifier
                         then
                            parent:SetModel(parent.hero_model_change.modifier)
                            if parent.hero_model_change.skin then
                                parent:SetSkin(parent.hero_model_change.skin)
                            end
                        end
                        if modifier_name == "modifier_dragon_knight_dragon_form" then
                            if parent:HasScepter() then
                                parent:SetMaterialGroup("3")
                            else
                                parent:SetMaterialGroup(parent.Slots["shapeshift"].style)
                            end
                        end
                        return 0.034
                    end
                end
            )
        elseif modifier_name == "modifier_legion_commander_press_the_attack" then
            if parent.Slots["back"] and parent.Slots["back"]["itemDef"] == "7930" then
                -- parent:StartGesture(ACT_SCRIPT_CUSTOM_0)
                StartAnimation(parent, {duration = 5, activity = ACT_SCRIPT_CUSTOM_0, rate = 1.0})
            end
        end
    end

    return true
end

-- 处理攻击弹道
-- is_attack:1
-- entindex_ability_const:-1
-- max_impact_time:0
-- entindex_target_const:185
-- move_speed:900
-- entindex_source_const:517
-- dodgeable:1
-- expire_time:0
function CHeroDemo:TrackingProjectileFilter(data)
    -- PrintTable(data)
    local hSource = EntIndexToHScript(data.entindex_source_const)
    if not hSource then
        -- PrintTable(data)
        return true
    end
    local hTarget = EntIndexToHScript(data.entindex_target_const)
    local move_speed = data.move_speed
    local p_name = hSource:GetRangedProjectileName()
    -- print(hSource, "new_projectile", hSource.new_projectile)
    if hSource.new_projectile then
        p_name = hSource.new_projectile
    end
    local hOwner = hSource:GetOwner()
    local prismatic = hSource.prismatic
    if (not prismatic) and hOwner then
        prismatic = hOwner.prismatic
    end
    if Wearable.PrismaticParticles and Wearable.PrismaticParticles[p_name] and prismatic then
        print(p_name)
        local p = ParticleManager:CreateParticle(p_name, PATTACH_CUSTOMORIGIN, hSource)
        local sHexColor = Wearable.prismatics[prismatic].hex_color
        local vColor = HexColor2RGBVector(sHexColor)
        ParticleManager:SetParticleControl(p, 16, Vector(1, 0, 0))
        ParticleManager:SetParticleControl(p, 15, vColor)
        ParticleManager:SetParticleControlEnt(
            p,
            0,
            hSource,
            PATTACH_POINT_FOLLOW,
            "attach_attack1",
            hSource:GetAbsOrigin(),
            true
        )
        ParticleManager:SetParticleControlEnt(
            p,
            1,
            hTarget,
            PATTACH_POINT_FOLLOW,
            "attach_hitloc",
            hTarget:GetAbsOrigin(),
            true
        )
        ParticleManager:SetParticleControl(p, 2, Vector(move_speed, 0, 0))
        local delay = (hTarget:GetAbsOrigin() - hSource:GetAbsOrigin()):Length2D() / move_speed
        local damage = hSource:GetAverageTrueAttackDamage(hTarget)
        Timers:CreateTimer(
            delay,
            function()
                ParticleManager:DestroyParticle(p, false)
                ParticleManager:ReleaseParticleIndex(p)
                local damageTable = {
                    victim = hTarget,
                    attacker = hSource,
                    damage = damage,
                    damage_type = DAMAGE_TYPE_PHYSICAL,
                    damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
                    ability = nil --Optional.
                }
                ApplyDamage(damageTable)
            end
        )
        return false
    end
    return true
end

function CHeroDemo:OnRequestCombination(data, response)
    local sHeroName = data.hero_name
    local page = data.page

    Http:GetRankPage(sHeroName, page, response)
end

function CHeroDemo:OnRequestComments(data, response)
    local sComID = data.combinationID
    local nPlayerID = data.PlayerID

    Http:GetComments(sComID, nPlayerID, response)
end

function CHeroDemo:OnLoadMoreComments(data, response)
    local sComID = data.combinationID
    local nPlayerID = data.PlayerID
    local nStart = data.start

    Http:LoadMoreComments(sComID, nPlayerID, nStart, response)
end

function CHeroDemo:OnSubmitComment(data, response)
    local sComID = data.combinationID
    local sContent = data.content
    local nPlayerID = data.PlayerID

    Http:SubmitComment(sComID, nPlayerID, sContent, response)
end

function CHeroDemo:OnCommendComment(data, response)
    local sCommentID = data.commentID
    local nPlayerID = data.PlayerID

    Http:CommendComment(sCommentID, nPlayerID, response)
end

function CHeroDemo:OnVote(data, response)
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)
    local nPlayerID = data.PlayerID

    Http:Vote(hUnit, nPlayerID, response)
end

function CHeroDemo:OnVoteCombination(data, response)
    local nComID = data.combinationID
    local nPlayerID = data.PlayerID

    Http:VoteCombination(nComID, nPlayerID, response)
end

function CHeroDemo:OnWearCombination(data)
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)
    local combinationID = data.combinationID

    Wearable:WearCombination(hUnit, combinationID)
end

function CHeroDemo:OnWearCourier(data)
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)
    local sItemDef = data.itemDef
    local sStyle = data.itemStyle
    local bFlying = ParseBool(data.bFlying)
    local bDire = ParseBool(data.bDire)

    Wearable:WearCourier(hUnit, sItemDef, sStyle, bFlying, bDire)
end

function CHeroDemo:OnWearWard(data)
    local nEntityIndex = data.unit
    local hUnit = EntIndexToHScript(nEntityIndex)
    local sItemDef = data.itemDef
    local sStyle = data.itemStyle

    Wearable:WearWard(hUnit, sItemDef, sStyle)
end

function CHeroDemo:OnRefreshGems(data, response)
    Wearable:RequestParticles(response)
end

function CHeroDemo:OnPlayerChat(data)
    -- print("OnPlayerChat")
    -- PrintTable(data)
    if data.text == "-show_itemdefs" then
        local playerID = data.playerid
        local hPlayer = PlayerResource:GetPlayer(playerID)
        CustomGameEventManager:Send_ServerToPlayer(hPlayer, "ShowItemdefs", {})
    end
end

function CHeroDemo:OnCreateOrder(data, response)
    local nPlayerID = data.PlayerID
    local sOrderType = data.order_type
    local sOrderName = data.order_name

    Http:CreateOrder(nPlayerID, sOrderType, sOrderName, response)
end

function CHeroDemo:OnCheckGemVip(data, response)
    local nPlayerID = data.PlayerID
    local response = function(hBody)
        if hBody.paid then
            ActivateGem(nPlayerID, hBody.expiration)
        end
    end
    Http:CheckGemVip(nPlayerID, response)
end

function ActivateGem(nPlayerID, expiration)
    print("ActivateGem", nPlayerID)
    local hPlayer = PlayerResource:GetPlayer(nPlayerID)
    _G.GemVips[nPlayerID] = true
    CustomGameEventManager:Send_ServerToPlayer(hPlayer, "ActivateGem", {expiration = expiration})
end

function CHeroDemo:OnCheckGemLoop(data)
    local nPlayerID = data.PlayerID
    local hPlayer = PlayerResource:GetPlayer(nPlayerID)
    local response = function(hBody)
        if hBody.paid then
            if hPlayer.CheckGemTimer then
                Timers:RemoveTimer(hPlayer.CheckGemTimer)
                hPlayer.CheckGemTimer = nil
            end
            if hPlayer.ExpireTimer then
                Timers:RemoveTimer(hPlayer.ExpireTimer)
                hPlayer.ExpireTimer = nil
            end
            ActivateGem(nPlayerID, hBody.expiration)
        end
    end

    if hPlayer.CheckGemTimer then
        Timers:RemoveTimer(hPlayer.CheckGemTimer)
    end
    hPlayer.CheckGemTimer =
        Timers:CreateTimer(
        0,
        function(...)
            Http:CheckGemVip(nPlayerID, response)
            return 4
        end
    )

    if hPlayer.ExpireTimer then
        Timers:RemoveTimer(hPlayer.ExpireTimer)
    end
    hPlayer.ExpireTimer =
        Timers:CreateTimer(
        300,
        function(...)
            if hPlayer.CheckGemTimer then
                Timers:RemoveTimer(hPlayer.CheckGemTimer)
                hPlayer.CheckGemTimer = nil
            end
            if hPlayer.ExpireTimer then
                Timers:RemoveTimer(hPlayer.ExpireTimer)
                hPlayer.ExpireTimer = nil
            end
        end
    )
end

function CHeroDemo:OnSwitchTinyModel(data, response)
    local unit_id = data.unit
    local hTiny = EntIndexToHScript(unit_id)
    local nModelIndex = data.model_index
    Wearable:SwitchTinyModel(hTiny, nModelIndex)
end

-- print(GetDedicatedServerKey("fitting room"))
