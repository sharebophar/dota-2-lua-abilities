--[[
  Wearable Library by pilaoda
  
--]]
if not Http then
    Http = {}
    Http.__index = Http
    _G.Http = Http
    Convars:RegisterConvar("test_steamID", "-1", "set test steamID", FCVAR_NOTIFY)
end

local ip = "http://120.78.56.197:4005"
local econ_ip = "http://120.78.56.197:4006"
if IsInToolsMode() then
    ip = "http://127.0.0.1:4005"
    econ_ip = "http://127.0.0.1:4006"
end

local function SetKey(req)
    local key1 = GetDedicatedServerKeyV2("hermit purple")
    local key2 = GetDedicatedServerKeyV2("star platinum")
    local key3 = GetDedicatedServerKeyV2("crazy diamond")
    local key4 = GetDedicatedServerKeyV2("gold experience")
    req:SetHTTPRequestGetOrPostParameter("ServerKey", key1..key2..key3..key4)
end

function Http:Vote(hUnit, nPlayerID, response)
    if (not IsValidEntity(hUnit)) or (not hUnit:IsAlive()) then
        return
    end

    if hUnit.sHeroName then
        local nHeroID = DOTAGameManager:GetHeroIDByName(hUnit.sHeroName)
        local steamID = PlayerResource:GetSteamAccountID(nPlayerID)
        local req = CreateHTTPRequestScriptVM("POST", ip .. "/vote")

        local combination = {}
        for sSlotName, hWear in pairs(hUnit.Slots) do
            local sItemDef = hWear["itemDef"]
            local sStyle = hWear["style"]
            local nSlotIndex = Wearable:GetSlotIndex(hUnit, sItemDef)
            if nSlotIndex < 10 then
                combination["itemDef" .. nSlotIndex] = sItemDef
                combination["style" .. nSlotIndex] = sStyle
            end
        end

        local test_steamID = Convars:GetStr("test_steamID")
        if test_steamID ~= "-1" then
            steamID = test_steamID
        end

        SetKey(req)
        req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
        req:SetHTTPRequestGetOrPostParameter("heroID", tostring(nHeroID))
        req:SetHTTPRequestGetOrPostParameter("combination", JSON:encode(combination))
        req:Send(
            function(result)
                if result.StatusCode ~= 200 then
                    Notifications:BottomToAll(
                        {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                    )
                    return
                end
                PrintTable(result)
                response(result.Body)
            end
        )
    end
end

function Http:VoteCombination(nComID, nPlayerID, response)
    local hCombination = Wearable.combination[nComID]
    local nHeroID = hCombination.heroID
    local steamID = PlayerResource:GetSteamAccountID(nPlayerID)
    local req = CreateHTTPRequestScriptVM("POST", ip .. "/vote")

    local test_steamID = Convars:GetStr("test_steamID")
    if test_steamID ~= "-1" then
        steamID = test_steamID
    end

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
    req:SetHTTPRequestGetOrPostParameter("heroID", tostring(nHeroID))
    req:SetHTTPRequestGetOrPostParameter("combination", JSON:encode(hCombination))
    req:Send(
        function(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
                return
            end
            PrintTable(result)
            response(result.Body)
        end
    )
end

function Http:GetVote(hUnit, nPlayerID)
    local sHeroName = hUnit.sHeroName
    local nHeroID = DOTAGameManager:GetHeroIDByName(sHeroName)
    local steamID = PlayerResource:GetSteamAccountID(nPlayerID)
    local req = CreateHTTPRequestScriptVM("POST", ip .. "/get_vote")
    local hPlayer = PlayerResource:GetPlayer(nPlayerID)

    local test_steamID = Convars:GetStr("test_steamID")
    if test_steamID ~= "-1" then
        steamID = test_steamID
    end

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
    req:SetHTTPRequestGetOrPostParameter("heroID", tostring(nHeroID))
    req:Send(
        function(result)
            print("GetVote")
            PrintTable(result)
            if result.StatusCode ~= 200 then
                -- Notifications:BottomToAll({text="ConnectFailed", duration=3, style={color="red", ["font-size"]="30px"}})
            elseif result.Body then
                local combination = JSON:decode(result.Body)
                if combination.combinationID then
                    Wearable:CacheCombination(combination)
                    Wearable:WearCombination(hUnit, combination.combinationID)
                    CustomGameEventManager:Send_ServerToPlayer(
                        hPlayer,
                        "CacheCurrentVoted",
                        {hero_name = sHeroName, combinationID = combination.combinationID}
                    )
                end
            end
        end
    )
end

local PAGE_LEN = 10 -- 排行榜每页包含搭配数
-- page从1开始算第一页
function Http:GetRankPage(sHeroName, page, response)
    local nHeroID = DOTAGameManager:GetHeroIDByName(sHeroName)
    local req = CreateHTTPRequestScriptVM("POST", ip .. "/get_rank")

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("heroID", tostring(nHeroID))
    req:SetHTTPRequestGetOrPostParameter("start", tostring((page - 1) * PAGE_LEN))
    req:SetHTTPRequestGetOrPostParameter("end", tostring(page * PAGE_LEN))
    req:Send(
        function(result)
            PrintTable(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
            elseif result.Body then
                local page = JSON:decode(result.Body)
                for _, hCom in pairs(page) do
                    for k, v in pairs(hCom) do
                        hCom[k] = tostring(v)
                    end
                end
                Wearable:CacheCombinationPage(page)
                response({hero_name = sHeroName, page = page})
            end
        end
    )
end

--
function Http:GetComments(sComID, nPlayerID, response)
    local req = CreateHTTPRequestScriptVM("POST", ip .. "/get_comments")
    local steamID = PlayerResource:GetSteamAccountID(nPlayerID)

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("combinationID", tostring(sComID))
    req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
    req:Send(
        function(result)
            PrintTable(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
            elseif result.Body then
                local hBody = JSON:decode(result.Body)
                local hRecentComments = hBody.RecentComments
                for _, hCom in pairs(hRecentComments) do
                    for k, v in pairs(hCom) do
                        hCom[k] = tostring(v)
                    end
                end
                local hGoodComments = hBody.GoodComments
                for _, hCom in pairs(hGoodComments) do
                    for k, v in pairs(hCom) do
                        hCom[k] = tostring(v)
                    end
                end
                response({comments = hBody})
            end
        end
    )
end

--
function Http:LoadMoreComments(sComID, nPlayerID, nStart, response)
    local req = CreateHTTPRequestScriptVM("POST", ip .. "/more_comments")
    local steamID = PlayerResource:GetSteamAccountID(nPlayerID)

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("combinationID", tostring(sComID))
    req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
    req:SetHTTPRequestGetOrPostParameter("start", tostring(nStart))
    req:Send(
        function(result)
            PrintTable(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
            elseif result.Body then
                local hComments = JSON:decode(result.Body)
                for _, hCom in pairs(hComments) do
                    for k, v in pairs(hCom) do
                        hCom[k] = tostring(v)
                    end
                end
                response({comments = hComments})
            end
        end
    )
end

--
function Http:SubmitComment(sComID, nPlayerID, sContent, response)
    local req = CreateHTTPRequestScriptVM("POST", ip .. "/comment")
    local steamID = PlayerResource:GetSteamAccountID(nPlayerID)

    local test_steamID = Convars:GetStr("test_steamID")
    if test_steamID ~= "-1" then
        steamID = test_steamID
    end

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
    req:SetHTTPRequestGetOrPostParameter("combinationID", tostring(sComID))
    req:SetHTTPRequestGetOrPostParameter("content", sContent)
    req:Send(
        function(result)
            PrintTable(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
            elseif result.Body then
                response(result.Body)
            end
        end
    )
end

--
function Http:CommendComment(sCommentID, nPlayerID, response)
    local req = CreateHTTPRequestScriptVM("POST", ip .. "/commend_comment")
    local steamID = PlayerResource:GetSteamAccountID(nPlayerID)

    local test_steamID = Convars:GetStr("test_steamID")
    if test_steamID ~= "-1" then
        steamID = test_steamID
    end

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
    req:SetHTTPRequestGetOrPostParameter("commentID", tostring(sCommentID))
    req:Send(
        function(result)
            PrintTable(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
            elseif result.Body then
                response(result.Body)
            end
        end
    )
end

function Http:RequestParticles(response)
    local req = CreateHTTPRequestScriptVM("POST", ip .. "/get_particles")

    print("RequestParticles", req)
    SetKey(req)
    req:Send(
        function(result)
            PrintTable(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
                response(false)
            elseif result.Body then
                response(result.Body)
            end
        end
    )
end
    
function Http:CreateOrder(nPlayerID, sOrderType, sOrderName, response)
    local req = CreateHTTPRequestScriptVM("POST", econ_ip .. "/create_order")
    
    print("CreateOrder", req)
    local steamID = PlayerResource:GetSteamAccountID(nPlayerID)
    local test_steamID = Convars:GetStr("test_steamID")
    if test_steamID ~= "-1" then
        steamID = test_steamID
    end

    -- print(steamID, type(steamID))
    -- if steamID ~= 135716847 and steamID ~= 929572676 and steamID ~= 990375349 then
    --     print("not test")
    --     return
    -- end

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
    req:SetHTTPRequestGetOrPostParameter("order_type", sOrderType)
    req:SetHTTPRequestGetOrPostParameter("order_name", sOrderName)
    req:Send(
        function(result)
            PrintTable(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
            elseif result.Body then
                local hBody = JSON:decode(result.Body)
                PrintTable(hBody)
                response(hBody)
            end
        end
    )
end
    
function Http:CheckGemVip(nPlayerID, response)
    local req = CreateHTTPRequestScriptVM("POST", econ_ip .. "/check_gem_vip")
    
    print("CheckGemVip", req)
    local steamID = PlayerResource:GetSteamAccountID(nPlayerID)
    local test_steamID = Convars:GetStr("test_steamID")
    if test_steamID ~= "-1" then
        steamID = test_steamID
    end

    SetKey(req)
    req:SetHTTPRequestGetOrPostParameter("steamID", tostring(steamID))
    req:Send(
        function(result)
            PrintTable(result)
            if result.StatusCode ~= 200 then
                Notifications:BottomToAll(
                    {text = "ConnectFailed", duration = 3, style = { color = "white", ["font-size"] = "30px", ["background-color"] = "rgb(136, 34, 34)", opacity = "0.5" }}
                )
            elseif result.Body then
                local hBody = JSON:decode(result.Body)
                PrintTable(hBody)
                response(hBody)
            end
        end
    )
end