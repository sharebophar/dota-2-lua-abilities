--[[ Utility Functions ]]
function PrintTable(t, indent)
    if type(t) ~= "table" then
        return
    end

    if not indent then
        indent = ""
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            if (v ~= t) then
                print(indent .. tostring(k) .. ":\n" .. indent .. "{")
                PrintTable(v, indent .. "  ")
                print(indent .. "}")
            end
        else
            print(indent .. tostring(k) .. ":" .. tostring(v))
        end
    end
end

function ShuffledList(list)
    local result = {}
    local count = #list
    for i = 1, count do
        local pick = RandomInt(1, #list)
        result[#result + 1] = list[pick]
        table.remove(list, pick)
    end
    return result
end

function string.starts(string, start)
    return string.sub(string, 1, string.len(start)) == start
end

function TableLength(t)
    local nCount = 0
    for _ in pairs(t) do
        nCount = nCount + 1
    end
    return nCount
end

function CHeroDemo:BroadcastMsg(sMsg)
    -- Display a message about the button action that took place
    local buttonEventMessage = sMsg
    --print( buttonEventMessage )
    local centerMessage = {
        message = buttonEventMessage,
        duration = 1.0,
        clearQueue = true -- this doesn't seem to work
    }
    FireGameEvent("show_center_message", centerMessage)
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == "") then
        return false
    end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function()
        return string.find(input, delimiter, pos, true)
    end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function String2Vector(s)
    local array = string.split(s, " ")
    return Vector(array[1], array[2], array[3])
end

function HexColor2RGBVector(sHexColor)
    local sHexR = string.sub(sHexColor, 2, 3)
    local sHexG = string.sub(sHexColor, 4, 5)
    local sHexB = string.sub(sHexColor, 6, 7)
    local nDecR = tonumber(sHexR, 16)
    local nDecG = tonumber(sHexG, 16)
    local nDecB = tonumber(sHexB, 16)
    return Vector(nDecR, nDecG, nDecB)
end

function string.remove_num(s)
    local len = string.len(s)
    local end_index = len
    while (string.byte(s, end_index) >= 48 and string.byte(s, end_index) <= 57 and end_index > 1) or
        string.sub(s, end_index, end_index) == "_" do
        end_index = end_index - 1
    end
    local sub = string.sub(s, 1, end_index)
    return sub
end

function ParseBool( value )
    if value == true then
        return true
    elseif value == 0 or value == "0" then
        return false
    elseif value == false or value == nil then
        return false
    else 
        return true
    end
end

function GetEnemyTeam( team )
    if team == DOTA_TEAM_GOODGUYS then
        return DOTA_TEAM_BADGUYS
    elseif team == DOTA_TEAM_BADGUYS then
        return DOTA_TEAM_GOODGUYS
    end
end