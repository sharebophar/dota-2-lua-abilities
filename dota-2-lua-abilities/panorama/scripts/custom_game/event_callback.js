function UniqueEventIDClosure() {
	var i = 0;
	return function () {
		i++;
		return i;
	}
}

function SendEventToServerWithCallback(event, data, callback) {
    var eventID = GetUniqueEventID();
    GameEvents.SendCustomGameEventToServer("EventCallback_Request", { "event":event, "eventID": eventID, "data": data });
    if (!EventCallbackMap.hasOwnProperty(event)) {
        EventCallbackMap[event] = {};
    }
    EventCallbackMap[event][eventID] = callback;
}

function ReceiveEventCallback(data_wrap) {
    var event = data_wrap.event
    var eventID = data_wrap.eventID;
    var Result = data_wrap.result;
    var callback = EventCallbackMap[event][eventID];
    callback(Result);
    delete EventCallbackMap[event][eventID];
}
(function () {
	GameEvents.Subscribe('EventCallback_Response', ReceiveEventCallback);
    GetUniqueEventID = UniqueEventIDClosure();
    EventCallbackMap = {};
})();