
function SwitchPrismatic(prismaticName) {
    return function () {
        $.Msg("SwitchPrismatic", prismaticName);
        let unit = Players.GetLocalPlayerPortraitUnit();
        SendEventToServerWithCallback(
            "SwitchPrismatic",
            { "unit": unit, "prismaticName": prismaticName },
            Nothing
        )
    }
}

function ToggleEthereal(etherealName) {
    return function () {
        $.Msg("ToggleEthereal", etherealName);
        let unit = Players.GetLocalPlayerPortraitUnit();
        SendEventToServerWithCallback(
            "ToggleEthereal",
            { "unit": unit, "etherealName": etherealName },
            Nothing
        )
    }
}

function CreatePrismaticsContainer() {
    let container = $("#GemContainer");
    let AvailablePrismatics = container.FindChildTraverse("AvailablePrismatics");

    let Prismatics = CustomNetTables.GetTableValue("gems", "prismatics");

    for (let key in Prismatics) {
        let prismaticName = Prismatics[key]["color_name"];
        let hexColor = Prismatics[key]["hex_color"];
        let PrismaticItem = $.CreatePanel("Panel", AvailablePrismatics, key);
        PrismaticItem.BLoadLayoutSnippet("PrismaticItem");

        let EconItem = PrismaticItem.FindChildTraverse("EconItem");
        let EconImage = EconItem.FindChildTraverse("EconItemIcon");
        EconImage.SetPanelEvent("onload", () => {
            let Image = EconImage.FindChildTraverse("Overlay");
            Image.style["wash-color"] = hexColor;
            let PrismaticName = PrismaticItem.FindChildTraverse("PrismaticName");
            PrismaticName.text = $.Localize("#" + prismaticName);
            PrismaticName.style["color"] = hexColor;
    
            let PrismaticColor = PrismaticItem.FindChildTraverse("PrismaticColor");
            PrismaticColor.text = hexColor2RGB(hexColor);
            PrismaticColor.style["color"] = hexColor;
    
            PrismaticItem.SetPanelEvent("onactivate", SwitchPrismatic(key));
        });
    }

    
    let unit = Players.GetLocalPlayerPortraitUnit();
    let PrismaticTable = CustomNetTables.GetTableValue("hero_prismatic", unit.toString());
    if (PrismaticTable) {
        let unitPrismaticName = PrismaticTable.prismatic_name;
        let PrismaticItem = $("#" + unitPrismaticName);
        let EconItem = PrismaticItem.FindChildTraverse("EconItem");
        if (CurrentSelectedPrismaticItem) {
            CurrentSelectedPrismaticItem.RemoveClass("GemItemSelected")
        }
        PrismaticItem.AddClass("GemItemSelected");
        CurrentSelectedPrismaticItem = PrismaticItem;
    }
}

function CreateEtherealsContainer() {
    let container = $("#GemContainer");
    let AvailableEthereals = container.FindChildTraverse("AvailableEthereals");

    let Ethereals = CustomNetTables.GetTableValue("gems", "ethereals");

    for (let etherealName in Ethereals) {
        let EtherealItem = $.CreatePanel("Panel", AvailableEthereals, etherealName);
        EtherealItem.BLoadLayoutSnippet("EtherealItem");

        let EtherealName = EtherealItem.FindChildTraverse("EtherealName");
        EtherealName.text = $.Localize("#" + etherealName);

        EtherealItem.SetPanelEvent("onactivate", ToggleEthereal(etherealName));
    }

    let ResetGemsButton = $.CreatePanel("Button", AvailableEthereals, "ResetGemsButton");
    ResetGemsButton.SetPanelEvent("onactivate", ResetGems);
    ResetGemsButton.AddClass("DemoButton");
    let ResetGemsButtonLabel = $.CreatePanel("Label", ResetGemsButton, "");
    ResetGemsButtonLabel.text = $.Localize("ResetGems");
}

function CreateGemContainer(table_name, key, value) {
    if (key == "prismatics") {
        CreatePrismaticsContainer();
    } else if (key == "ethereals") {
        CreateEtherealsContainer();
    }
}

function ResetGems() {
    let unit = Players.GetLocalPlayerPortraitUnit();
    GameEvents.SendCustomGameEventToServer("ResetGems", { "unit": unit });
}

function OnPrismaticSelected(table_name, unit, data) {
    let unit_id = parseInt(unit);
    let prismaticName = data.prismatic_name
    if (CurrentSelectedPrismaticItem) {
        Game.EmitSound('ui.crafting_gem_drop');
        CurrentSelectedPrismaticItem.RemoveClass("GemItemSelected")
    }
    if (unit_id == Players.GetLocalPlayerPortraitUnit() && prismaticName) {
        Game.EmitSound('ui.crafting_gem_applied');
        let PrismaticItem = $("#" + prismaticName);
        PrismaticItem.AddClass("GemItemSelected");
        CurrentSelectedPrismaticItem = PrismaticItem;
    }
}

function OnEtherealToggled(table_name, unit, Ethereals) {
    let unit_id = parseInt(unit);
    if (unit_id == Players.GetLocalPlayerPortraitUnit()) {
        for (let etherealName in Ethereals) {
            let EtherealItem = $("#" + etherealName);
            let toggled = Ethereals[etherealName];
            if (toggled == false) {
                if (EtherealItem.BHasClass("GemItemSelected")) {
                    Game.EmitSound('ui.crafting_gem_drop');
                    EtherealItem.SetHasClass("GemItemSelected", false);
                }
            } else {
                if (!EtherealItem.BHasClass("GemItemSelected")) {
                    Game.EmitSound('ui.crafting_pulse');
                    EtherealItem.SetHasClass("GemItemSelected", true);
                }
            }
        }
    }
}

function OnSelectionChangeForGem(unit, old_unit) {
    if (CurrentSelectedPrismaticItem) {
        CurrentSelectedPrismaticItem.RemoveClass("GemItemSelected")
    }

    let PrismaticTable = CustomNetTables.GetTableValue("hero_prismatic", unit.toString());
    if (PrismaticTable) {
        let unitPrismaticName = PrismaticTable.prismatic_name;
        let PrismaticItem = $("#" + unitPrismaticName);
        if (PrismaticItem) {
            PrismaticItem.AddClass("GemItemSelected");
            CurrentSelectedPrismaticItem = PrismaticItem;
        }
    }

    let Ethereals = CustomNetTables.GetTableValue("hero_ethereals", unit.toString());
    let EtherealItems = $("#AvailableEthereals").Children();
    if (Ethereals) {
        for (let EtherealItem of EtherealItems) {
            let etherealName = EtherealItem.id;
            let toggled = Ethereals[etherealName];
            if (toggled) {
                EtherealItem.SetHasClass("GemItemSelected", true);
            } else {
                EtherealItem.SetHasClass("GemItemSelected", false);
            }
        }
    } else {
        for (let EtherealItem of EtherealItems) {
            EtherealItem.SetHasClass("GemItemSelected", false);
        }
    }
}

function ToggleGemPanel() {
    if ($.GetContextPanel().BHasClass('GemMinimized')) {
        Game.EmitSound('panorama.panorama_menu_activate_open');
    } else {
        Game.EmitSound('panorama.panorama_menu_activate_close');
    }
    $.GetContextPanel().ToggleClass('GemMinimized');
}

function RefreshGems() {
    SendEventToServerWithCallback(
        "RefreshGems",
        {},
        function (params) {
            $.Msg("RefreshGems ", params);
            if (params) {
                $("#RefreshButton").SetHasClass('Hidden', true);
            }
        }
    )
}

(function () {
    CustomNetTables.SubscribeNetTableListener("hero_prismatic", OnPrismaticSelected);
    CustomNetTables.SubscribeNetTableListener("hero_ethereals", OnEtherealToggled);

    CurrentSelectedPrismaticItem = null;

    CustomNetTables.SubscribeNetTableListener("gems", CreateGemContainer);

    RegisterSelectionChange(OnSelectionChangeForGem);

    RefreshGems();
})();