
function GetHeroName (unit) {
    var unitName = GetUnitName(unit);
    return unitName.substring(0, 9) + "hero" + unitName.substring(13);
};

function GetUnitName (unit) {
    var full_unit_name = Entities.GetUnitName(unit);
    var origin_unit_name = full_unit_name.split("__")[0];
    return origin_unit_name;
};

function forward2yaw (forward) {
    var x = forward[0];
    var y = forward[1];
    var atan2 = Math.atan2(y, x);
    var angle = atan2 / Math.PI * 180;
    return angle + 60;
};

function hexColor2RGB (hexColor) {
    var hexR = hexColor.substring(1, 3);
    var hexG = hexColor.substring(3, 5);
    var hexB = hexColor.substring(5, 7);
    var decR = parseInt(hexR, 16);
    var decG = parseInt(hexG, 16);
    var decB = parseInt(hexB, 16);
    var RGB = "( " + decR + ", " + decG + ", " + decB + " )";
    return RGB;
};

function Nothing () {
};

function UniqueIDClosure () {
    var i = 0;
    return function () {
        i++;
        return "UID" + i.toString();
    };
};

// key：表示数组中的属性
// bAscSort:为true表示按照升序排序，false表示按照降序排序；
function keysort (key, bAscSort) {
    return function (a, b) {
        return bAscSort ? (a[key] - b[key]) : (b[key] - a[key]);
    };
};

function ShowItemdefs() {
    var unit = Players.GetLocalPlayerPortraitUnit();
    var unitName = GetUnitName(unit);
    if (unitName.substring(9, 13) == "unit") {
        $.Msg(GetHeroName(unit));
        var Wearables = CustomNetTables.GetTableValue("hero_wearables", unit.toString());
        for (var slotName in Wearables) {
            var EquipedItem = Wearables[slotName];
            var equipedItemDef = EquipedItem["itemDef"];
            $.Msg("SlotName: ", slotName, "  ItemDef: ", equipedItemDef);
        }
    }
};

function IsWearableUnit (unit) {
    var unitName = GetUnitName(unit);
    return unitName.substring(9, 13) == "unit";
};

function IsCourier (unit) {
    var unitName = GetUnitName(unit);
    return unitName == "npc_dota_courier_creature";
};

(function () {
    GameEvents.Subscribe('ShowItemdefs', ShowItemdefs);
})();