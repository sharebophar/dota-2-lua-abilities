function CreateOrder(order_type) {
    var order_name = $("#Gem30").GetSelectedButton().id;
    SendEventToServerWithCallback(
        "CreateOrder",
        {
            "order_type": order_type,
            "order_name": order_name
        },
        function (params) {
            $.Msg(params);
            SetQRCode(params);
        }
    );
}

function SetQRCode(params) {
    $.Msg("SetQRCode ", params);
    var e = encodeURIComponent(JSON.stringify(params));
    $.Msg(e);
    $("#QRCode").SetURL('http://120.78.56.197:4006/pay?data=' + e);
    // $("#QRCode").SetURL('http://127.0.0.1:4006/pay?data=' + e);
    GameEvents.SendCustomGameEventToServer("CheckGemLoop", {});
    $("#QRCode").style.visibility = "visible";
}

function ActivateGem(data) {
    var expiration = parseInt(data.expiration);
    $("#GemMaskContainer").SetHasClass("ShowMask", false);
    Game.EmitSound('terrorblade_arcana.stinger.buy_back');
    var msg = { "text": "ActivateGemVip", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
    GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);

    var timestamp = parseInt(expiration / 1000);;
    $("#ExperiationDate").SetDialogVariableTime("timestamp", timestamp);
    $("#ExperiationDate").text = $.Localize("GemExpiration") + $("#ExperiationDate").text;
    $("#ExperiationDate").style.visibility = "visible";
}

(function () {
    GameEvents.Subscribe('ActivateGem', ActivateGem);
    GameEvents.SendCustomGameEventToServer("CheckGemVip", {});
})();
