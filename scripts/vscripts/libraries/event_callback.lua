--[[
  EventCallback Library by pilaoda

  client request and server response with only one event name and one anonymous callback function.
  
  support both syncronize return value and asyncronize callback to send value.
--]]
if not EventCallback then
    EventCallback = {}
    EventCallback.__index = EventCallback
    _G.EventCallback = EventCallback
end

function EventCallback:Init()
    EventCallback.handlers = {}
    EventCallback.AsyncHandlers = {}
    CustomGameEventManager:RegisterListener(
        "EventCallback_Request",
        Dynamic_Wrap(EventCallback, "EventCallbackManager")
    )
end

function EventCallback:EventCallbackManager(data_wrap)
    local sEvent = data_wrap.event
    local nEventID = data_wrap.eventID
    local hData = data_wrap.data
    local nPlayerID = data_wrap.PlayerID
    local hPlayer = PlayerResource:GetPlayer(nPlayerID)
    hData.PlayerID = nPlayerID

    local handler = EventCallback.handlers[sEvent]
    if handler then
        local hResult = handler(hData)

        CustomGameEventManager:Send_ServerToPlayer(
            hPlayer,
            "EventCallback_Response",
            {event = sEvent, eventID = nEventID, result = hResult}
        )
    else
        handler = EventCallback.AsyncHandlers[sEvent]
        handler(
            hData,
            function(hResult)
                CustomGameEventManager:Send_ServerToPlayer(
                    hPlayer,
                    "EventCallback_Response",
                    {event = sEvent, eventID = nEventID, result = hResult}
                )
            end
        )
    end
end

function EventCallback:RegisterHandler(event, handler)
    self.handlers[event] = handler
end

function EventCallback:RegisterAsyncHandler(event, handler)
    self.AsyncHandlers[event] = handler
end

if not EventCallback.handlers then
    EventCallback:Init()
end
