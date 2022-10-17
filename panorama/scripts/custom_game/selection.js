
function _OnSelectionChange(unit, old_unit) {

    for (var handler of handlers) {
        handler(unit, old_unit);
    }
}

function CheckSelectionUnitLoop() {
    var unit = Players.GetLocalPlayerPortraitUnit();
    if (unit != CurrentSelectionUnit) {
        _OnSelectionChange(unit, CurrentSelectionUnit);
    }
    CurrentSelectionUnit = unit;
    $.Schedule(FRAME_TIME, CheckSelectionUnitLoop);
}

function RegisterSelectionChange(callback) {
    handlers.push(callback);
}

(function () {
    FRAME_TIME = 1 / 30;

    CurrentSelectionUnit = null;
    handlers = [];

    CheckSelectionUnitLoop();
})();