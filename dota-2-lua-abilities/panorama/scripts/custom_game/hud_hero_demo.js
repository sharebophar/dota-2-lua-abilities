function ToggleEnemyHeroPicker() {
    $('#SelectEnemyHeroContainer').ToggleClass('HeroPickerVisible');
}

function ToggleAllyHeroPicker() {
    $('#SelectAllyHeroContainer').ToggleClass('HeroPickerVisible');
}


function SpawnEnemyNewHero(nHeroID) {
    $('#SelectEnemyHeroContainer').RemoveClass('HeroPickerVisible');
    GameEvents.SendCustomGameEventToServer('SpawnEnemyButtonPressed', {
        sHeroID: String(nHeroID),
        nSelectedUnit:  Players.GetLocalPlayerPortraitUnit()
    });
}

function SpawnAllyNewHero(nHeroID) {
    $('#SelectAllyHeroContainer').RemoveClass('HeroPickerVisible');
    GameEvents.SendCustomGameEventToServer('SpawnAllyButtonPressed', {
        sHeroID: String(nHeroID),
        nSelectedUnit:  Players.GetLocalPlayerPortraitUnit()
    });
}

/*
hero_wearables : {
	unit_id : {
		slotName : {
			"itemDef" : string,
			"model" : string,
			"particles" : {
				pid : string;
			}
		}
	}
}

hero_available_items : {
	unit_name : {
		slot_name : {
			"SlotIndex" : string,
			"SlotText" : string,
			"DefaultItem" : string(itemDef),
			"ItemDefs" : { // available items
				i : string(itemdef)
				...
			}
		},
		"bundles" : {
			i : string(itemdef)
			...
		}
	}
}

*/

// 点击槽位切换可选物品栏闭包
function SelectSlot(EconItemSlot, SlotStorePanel) {
    return function () {
        Game.EmitSound('ui.books.pageturns');
        let StyleMenus = $.GetContextPanel().FindChildrenWithClassTraverse("EconItemStyleContents");
        let unit = Players.GetLocalPlayerPortraitUnit();
        let container = $("#UnitItemContainer" + unit.toString());
        for (let child of StyleMenus) {
            child.SetHasClass("Hidden", true);
        }

        if (EconItemSlot != null) {
            let EconItemSlotParent = EconItemSlot.GetParent();
            for (let child of EconItemSlotParent.Children()) {
                child.SetHasClass("Selected", false);
            }
            EconItemSlot.SetHasClass("Selected", true);
            if (container) {
                container.FindChildTraverse("Bundle").SetHasClass("SourceButtonDisabled", true);
                container.FindChildTraverse("Single").SetHasClass("SourceButtonDisabled", false);
            }
        } else {
            // 点击面板，切换到捆绑包栏
            let children = $.GetContextPanel().FindChildrenWithClassTraverse("Selected");
            for (let child of children) {
                if (child.BHasClass("EconItemSlot")) {
                    child.SetHasClass("Selected", false);
                }
            }
            if (container) {
                container.FindChildTraverse("Bundle").SetHasClass("SourceButtonDisabled", false);
                container.FindChildTraverse("Single").SetHasClass("SourceButtonDisabled", true);
            }
        }

        let SlotStoreParent = SlotStorePanel.GetParent();
        for (let child of SlotStoreParent.Children()) {
            child.SetHasClass("Hidden", true);
        }
        SlotStorePanel.SetHasClass("Hidden", false);
    }
};

// 切换饰品闭包
function SwitchWearable(itemDef, itemStyle) {
    if (!itemStyle) {
        itemStyle = 0;
    }
    return function () {
        $.Msg('SwitchWearable ', itemDef, ' ', itemStyle);
        let unit = Players.GetLocalPlayerPortraitUnit();
        GameEvents.SendCustomGameEventToServer("SwitchWearable", { "unit": unit, "itemDef": itemDef, "itemStyle": itemStyle });
    }
};

// 切换信使闭包
function SwitchCourier(itemDef, itemStyle, bFlying, bDire) {
    return function () {
        $.Msg('SwitchCourier ', itemDef, ' ', itemStyle, ' ', bFlying, ' ', bDire);

        // 必须重新设一个新变量，否则闭包将维护变量
        let _itemDef = itemDef;
        let _itemStyle = itemStyle;
        let _bFlying = bFlying;
        let _bDire = bDire;

        let unit = Players.GetLocalPlayerPortraitUnit();
        let container = $("#UnitItemContainer" + unit.toString());
        if (container) {
            let CourierSelectorContainer = container.FindChildTraverse("CourierSelectorContainer");
            if (CourierSelectorContainer.bFlying && _bFlying === undefined) {
                _bFlying = CourierSelectorContainer.bFlying;
            }
        }

        if (!_itemStyle) {
            _itemStyle = 0;
        }
        if (!_bFlying) {
            _bFlying = false;
        }
        if (!_bDire) {
            _bDire = false;
        }

        SendEventToServerWithCallback(
            "SwitchCourier",
            {
                "unit": unit,
                "itemDef": _itemDef,
                "itemStyle": _itemStyle,
                "bFlying": _bFlying,
                'bDire': _bDire,
            },
            function (params) {
                Game.EmitSound('ui.courier_in_use');

                let slotName = "courier";
                if (container) {
                    let CourierSelectorContainer = container.FindChildTraverse("CourierSelectorContainer");
                    CourierSelectorContainer.itemDef = _itemDef;
                    CourierSelectorContainer.itemStyle = _itemStyle;
                    CourierSelectorContainer.bFlying = _bFlying;
                    CourierSelectorContainer.bDire = _bDire;

                    let TeamSelectorContainer = container.FindChildTraverse("TeamSelectorContainer");
                    if (_bDire) {
                        TeamSelectorContainer.SetHasClass("DireSelected", true);
                    } else {
                        TeamSelectorContainer.SetHasClass("DireSelected", false);
                    }

                    let FlySelectorContainer = container.FindChildTraverse("FlySelectorContainer");
                    if (_bFlying) {
                        FlySelectorContainer.SetHasClass("FlySelected", true);
                    } else {
                        FlySelectorContainer.SetHasClass("FlySelected", false);
                    }

                    let EquipContainer = container.FindChildTraverse("EquipItemContainer");
                    let EconItemSlot = EquipContainer.FindChildTraverse(slotName);

                    if (EconItemSlot) {
                        let EconItem = GetEconItem(EconItemSlot);
                        let StyleMenu = $("#" + EconItem.id + "StyleMenu");

                        EconItem.DeleteAsync(0);
                        if (StyleMenu) {
                            StyleMenu.DeleteAsync(0);
                        }

                        let uid = GetUniqueID();
                        const EconItemPanel = $.CreatePanelWithProperties("DOTAEconItem", EconItemSlot, uid, {itemdef: _itemDef, itemstyle: _itemStyle});
                        EconItemPanel.AddClass("DisableInspect");
                        EconItemPanel.SetPanelEvent("onload", () => {
                            SetEconItemButtons(uid, _itemDef, _itemStyle);
                        });
                    }
                }
            }
        );
    }
};

function SwitchCourierTeam(bDire) {
    let unit = Players.GetLocalPlayerPortraitUnit();
    let container = $("#UnitItemContainer" + unit.toString());
    if (container) {
        let CourierSelectorContainer = container.FindChildTraverse("CourierSelectorContainer");
        let itemDef = CourierSelectorContainer.itemDef;
        let itemStyle = CourierSelectorContainer.itemStyle;
        let bFlying = CourierSelectorContainer.bFlying;
        SwitchCourier(itemDef, itemStyle, bFlying, bDire)();
    }
}

function SwitchCourierFly(bFlying) {
    let unit = Players.GetLocalPlayerPortraitUnit();
    let container = $("#UnitItemContainer" + unit.toString());
    if (container) {
        let CourierSelectorContainer = container.FindChildTraverse("CourierSelectorContainer");
        let itemDef = CourierSelectorContainer.itemDef;
        let itemStyle = CourierSelectorContainer.itemStyle;
        let bDire = CourierSelectorContainer.bDire;
        SwitchCourier(itemDef, itemStyle, bFlying, bDire)();
    }
}

// 切换守卫闭包
function SwitchWard(itemDef, itemStyle) {
    return function () {
        $.Msg('SwitchWard ', itemDef, ' ', itemStyle);

        let _itemDef = itemDef;
        let _itemStyle = itemStyle;
        let unit = Players.GetLocalPlayerPortraitUnit();
        let container = $("#UnitItemContainer" + unit.toString());

        if (!itemStyle) {
            itemStyle = 0;
        }

        SendEventToServerWithCallback(
            "SwitchWard",
            {
                "unit": unit,
                "itemDef": itemDef,
                "itemStyle": itemStyle,
            },
            function (params) {
                Game.EmitSound('DOTA_Item.ObserverWard.Activate');

                let slotName = "ward";
                if (container) {
                    let EquipContainer = container.FindChildTraverse("EquipItemContainer");
                    let EconItemSlot = EquipContainer.FindChildTraverse(slotName);

                    if (EconItemSlot) {
                        let EconItem = GetEconItem(EconItemSlot);
                        let StyleMenu = $("#" + EconItem.id + "StyleMenu");

                        EconItem.DeleteAsync(0);
                        if (StyleMenu) {
                            StyleMenu.DeleteAsync(0);
                        }

                        let uid = GetUniqueID();
                        const EconItemPanel = $.CreatePanelWithProperties("DOTAEconItem", EconItemSlot, uid, {itemdef: _itemDef, itemstyle: _itemStyle});
                        EconItemPanel.AddClass("DisableInspect");
                        EconItemPanel.SetPanelEvent("onload", () => {
                            SetEconItemButtons(uid, _itemDef, _itemStyle);
                        });
                    }
                }
            }
        );
    }
};

function CreateSelectCosmeticsForUnit(unit) {
    let origin_unit = ID_Map[unit] || unit;
    $.Msg("CreateSelectCosmeticsForUnit", origin_unit, ' ', unit);
    let container = $.CreatePanel("Panel", $("#HeroInspectBackground"), "UnitItemContainer" + origin_unit.toString());
    container.BLoadLayoutSnippet("EconItemContainer");
    let EquipContainer = container.FindChildTraverse("EquipItemContainer");
    let AvailableItemsCarousel = container.FindChildTraverse("AvailableItemsCarousel");

    if (IsWearableUnit(unit)) {
        let Wearables = CustomNetTables.GetTableValue("hero_wearables", unit.toString());
        let AvailableItems = CustomNetTables.GetTableValue("hero_available_items", GetUnitName(unit));

        // 创建捆绑包可更换装备栏
        if (AvailableItems && AvailableItems["bundles"]) {
            let Bundles = AvailableItems["bundles"];
            let BundlePanel = $.CreatePanel("DelayLoadPanel", AvailableItemsCarousel, "bundle");
            BundlePanel.AddClass("CarouselPage");
            for (let k in Bundles) {
                let storeItemDef = Bundles[k];
                let storeItemID = "StoreItem" + storeItemDef;

                const StoreItemPanel = $.CreatePanelWithProperties("DOTAStoreItem", BundlePanel, storeItemID, {itemdef: storeItemDef});
                StoreItemPanel.style.width = "180px";
                StoreItemPanel.style.height = "200px";
                StoreItemPanel.style.marginRight = "10px";
                StoreItemPanel.style.marginBottom = "10px";
                StoreItemPanel.SetPanelEvent("onactivate", SwitchWearable(storeItemDef));

                let StoreItem = BundlePanel.FindChildTraverse(storeItemID);

                // 饰品图片会挡住父面板的点击事件，但又需要它的tooltip，不能关闭hittest
                let ItemImage = StoreItem.FindChildTraverse("ItemImage");
                ItemImage.SetPanelEvent("onactivate", SwitchWearable(storeItemDef));

                let PurchaseButton = StoreItem.FindChildTraverse("PurchaseButton");
                PurchaseButton.visible = false;
            }
            EquipContainer.SetPanelEvent("onactivate", SelectSlot(null, BundlePanel));
            let BundleButton = container.FindChildTraverse("Bundle");
            BundleButton.SetPanelEvent("onactivate", SelectSlot(null, BundlePanel));
        }
        
        let SlotArray = SortSlots(AvailableItems);
        for (let slotIndex = 0; slotIndex < SlotArray.length; slotIndex++) {
            let Slot = SlotArray[slotIndex];
            
            if (Slot.DisplayInLoadout == 0) {
                continue;
            }
            
            let slotName = Slot.SlotName;
            let EquipedItem = Wearables[slotName];
            if (!EquipedItem) {
                continue;
            }
            let equipedItemDef = EquipedItem["itemDef"];
            let equipedItemStyle = EquipedItem["style"];
            
            // 创建单一槽位格
            let EconItemSlot = $.CreatePanel("Panel", EquipContainer, slotName);
            EconItemSlot.BLoadLayoutSnippet("EconItemSlot");
            
            let SlotLabel = EconItemSlot.FindChildTraverse("SlotName");
            SlotLabel.text = $.Localize(Slot.SlotText);
            
            let uid = GetUniqueID();

            const EconItem = $.CreatePanelWithProperties("DOTAEconItem", EconItemSlot, uid, {itemdef: equipedItemDef, itemstyle: equipedItemStyle});
            EconItem.AddClass("DisableInspect");
            EconItem.SetPanelEvent("onload", () => {
                SetEconItemButtons(uid, equipedItemDef, equipedItemStyle);
            });
            EconItem.SetPanelEvent("oncontextmenu", () => {
                ShowDetailButton(uid, equipedItemDef, equipedItemStyle);
            });
            
            // 创建该槽位可更换装备栏
            let DelayLoadPanel = $.CreatePanel("DelayLoadPanel", AvailableItemsCarousel, slotName);
            DelayLoadPanel.AddClass("CarouselPage");
            for (let k in Slot["ItemDefs"]) {
                let storeItemDef = Slot["ItemDefs"][k];
                let storeItemID = "StoreItem" + storeItemDef;

                const StoreItem = $.CreatePanelWithProperties("DOTAStoreItem", DelayLoadPanel, storeItemID, {itemdef: storeItemDef});
                StoreItem.style.width = "180px";
                StoreItem.style.height = "200px";
                StoreItem.style.marginRight = "10px";
                StoreItem.style.marginBottom = "10px";
                StoreItem.SetPanelEvent("onactivate", SwitchWearable(storeItemDef));
                
                // 饰品图片会挡住父面板的点击事件，但又需要鼠标停留时它的tooltip，不能关闭hittest
                let ItemImage = StoreItem.FindChildTraverse("ItemImage");
                ItemImage.SetPanelEvent("onactivate", SwitchWearable(storeItemDef));
                
                let PurchaseButton = StoreItem.FindChildTraverse("PurchaseButton");
                PurchaseButton.visible = false;
            }
            DelayLoadPanel.SetHasClass("Hidden", true);

            EconItemSlot.SetPanelEvent("onactivate", SelectSlot(EconItemSlot, DelayLoadPanel));
        }

        if (GetHeroName(unit) == "npc_dota_hero_tiny") {
            let TinyModelButtons = $.CreatePanel("Panel", EquipContainer, "TinyModelButtons");
            TinyModelButtons.BLoadLayoutSnippet("TinyModelButtons");
            let Model1 = TinyModelButtons.FindChildTraverse("Model1");
            Model1.checked = true;
        }
    } else if (IsCourier(unit)) {
        let AvailableItems = CustomNetTables.GetTableValue("other_available_items", "courier");

        let slotName = "courier";
        // 创建单一槽位格
        let EconItemSlot = $.CreatePanel("Panel", EquipContainer, slotName);
        EconItemSlot.BLoadLayoutSnippet("EconItemSlot");

        let SlotLabel = EconItemSlot.FindChildTraverse("SlotName");
        SlotLabel.text = $.Localize("DOTA_GlobalItems_Couriers");

        let uid = GetUniqueID();
        let equipedItemDef = "595";
        let equipedItemStyle = 0;
        const EconItemPanel = $.CreatePanelWithProperties("DOTAEconItem", EconItemSlot, uid, {itemdef: equipedItemDef, itemstyle: equipedItemStyle});
        EconItemPanel.AddClass("DisableInspect");
        EconItemPanel.SetPanelEvent("onload", () => {
            SetEconItemButtons(uid, equipedItemDef, equipedItemStyle);
        });
        EconItemPanel.SetPanelEvent("oncontextmenu", () => {
            ShowDetailButton(uid, equipedItemDef, equipedItemStyle);
        });

        // 创建队伍和飞行选择器
        let CourierSelectorContainer = $.CreatePanel("Panel", EquipContainer, "CourierSelectorContainer");
        CourierSelectorContainer.BLoadLayoutSnippet("CourierSelectorContainer");
        CourierSelectorContainer.itemDef = equipedItemDef;
        CourierSelectorContainer.itemStyle = equipedItemStyle;
        CourierSelectorContainer.bFlying = false;
        CourierSelectorContainer.bDire = false;

        // 创建可更换装备栏
        let DelayLoadPanel = $.CreatePanel("DelayLoadPanel", AvailableItemsCarousel, "courier");
        DelayLoadPanel.AddClass("CarouselPage");
        for (let storeItemDef in AvailableItems) {
            let storeItemID = "StoreItem" + storeItemDef;
            const StoreItem = $.CreatePanelWithProperties("DOTAStoreItem", DelayLoadPanel, storeItemID, {itemdef: storeItemDef});
            StoreItem.style.width = "180px";
            StoreItem.style.height = "200px";
            StoreItem.style.marginRight = "10px";
            StoreItem.style.marginBottom = "10px";
            StoreItem.SetPanelEvent("onactivate", SwitchCourier(storeItemDef));

            // 饰品图片会挡住父面板的点击事件，但又需要鼠标停留时它的tooltip，不能关闭hittest
            let ItemImage = StoreItem.FindChildTraverse("ItemImage");
            ItemImage.SetPanelEvent("onactivate", SwitchCourier(storeItemDef));
        }
    } else if (Entities.IsWard(unit)) {
        let AvailableItems = CustomNetTables.GetTableValue("other_available_items", "ward");

        let slotName = "ward";
        // 创建单一槽位格
        let EconItemSlot = $.CreatePanel("Panel", EquipContainer, slotName);
        EconItemSlot.BLoadLayoutSnippet("EconItemSlot");

        let SlotLabel = EconItemSlot.FindChildTraverse("SlotName");
        SlotLabel.text = $.Localize("DOTA_GlobalItems_Wards");

        let uid = GetUniqueID();
        let equipedItemDef = "596";
        let equipedItemStyle = 0;

        const EconItemPanel = $.CreatePanelWithProperties("DOTAEconItem", EconItemSlot, uid, {itemdef: equipedItemDef, itemstyle: equipedItemStyle});
        EconItemPanel.AddClass("DisableInspect");
        EconItemPanel.SetPanelEvent("onload", () => {
            SetEconItemButtons(uid, equipedItemDef, equipedItemStyle);
        });
        EconItemPanel.SetPanelEvent("oncontextmenu", () => {
            ShowDetailButton(uid, equipedItemDef, equipedItemStyle);
        });

        // 创建可更换装备栏
        let DelayLoadPanel = $.CreatePanel("DelayLoadPanel", AvailableItemsCarousel, "ward");
        DelayLoadPanel.AddClass("CarouselPage");
        for (let storeItemDef in AvailableItems) {
            let storeItemID = "StoreItem" + storeItemDef;
            const StoreItem = $.CreatePanelWithProperties("DOTAStoreItem", DelayLoadPanel, storeItemID, {itemdef: storeItemDef});
            StoreItem.style.width = "180px";
            StoreItem.style.height = "200px";
            StoreItem.style.marginRight = "10px";
            StoreItem.style.marginBottom = "10px";
            StoreItem.SetPanelEvent("onactivate", SwitchWard(storeItemDef));

            // 饰品图片会挡住父面板的点击事件，但又需要鼠标停留时它的tooltip，不能关闭hittest
            let ItemImage = StoreItem.FindChildTraverse("ItemImage");
            ItemImage.SetPanelEvent("onactivate", SwitchWard(storeItemDef));
        }
    } else {
        EquipContainer.SetHasClass("NotWearable", true);
    }
}

function SetEconItemButtons(econItemID, itemDef, itemStyle) {
    let EconItem = $("#" + econItemID);
    let EconItemSlot = EconItem.GetParent()
    let slotName = EconItemSlot.id
    let position = EconItemSlot.GetPositionWithinWindow();
    let x = position.x / EconItemSlot.actualuiscale_x
    let y = (position.y + EconItemSlot.actuallayoutheight) / EconItemSlot.actualuiscale_y;

    if (itemStyle === undefined) {
        itemStyle = 0;
    }
    let MultiStyle = EconItem.FindChildTraverse("MultiStyle");
    
    $.Schedule(0, ()=> {
        if (MultiStyle.visible || slotName == "shapeshift") {
            let unit = Players.GetLocalPlayerPortraitUnit();
            let imageSrc = null;
            let AvailableStylesList = null
            if (IsWearableUnit(unit)) {
                let AvailableItems = CustomNetTables.GetTableValue("hero_available_items", GetUnitName(unit));
                AvailableStylesList = AvailableItems[slotName]["styles"][itemDef];
            } else if (IsCourier(unit)) {
                let AvailableItems = CustomNetTables.GetTableValue("other_available_items", "courier");
                AvailableStylesList = AvailableItems[itemDef]["styles"];
            } else if (Entities.IsWard(unit)) {
                let AvailableItems = CustomNetTables.GetTableValue("other_available_items", "ward");
                AvailableStylesList = AvailableItems[itemDef]["styles"];
            }
    
            if (AvailableStylesList
                && AvailableStylesList[itemStyle.toString()]
                && AvailableStylesList[itemStyle.toString()].icon_path) {
                imageSrc = "s2r://panorama/images/" + AvailableStylesList[itemStyle.toString()].icon_path + "_png.vtex";
            }
    
            let SelectStyle = MultiStyle.FindChildTraverse("MultiStyleSelectedStyle");
            let total = SelectStyle.text.split('/')[1];
            if (slotName == "shapeshift") {
                total = 3;
                MultiStyle.visible = true;
            }
            
            SelectStyle.text = (itemStyle + 1).toString() + "/" + total;
    
            let StyleMenu = $.CreatePanel("Panel", $.GetContextPanel(), econItemID + "StyleMenu");
            StyleMenu.BLoadLayoutSnippet("EconItemStyleContextMenu");
            
            let EconItemIcon = EconItem.FindChildTraverse("EconItemIcon");
            
            if (imageSrc) {
                EconItemIcon.SetImage(imageSrc);
            }
            
            StyleMenu.SetPositionInPixels(x, y, 0);
            
            let StylesList = StyleMenu.FindChildTraverse("StylesList");
            for (let iStyle = 0; iStyle < parseInt(total); iStyle++) {
                let StyleEntry = $.CreatePanel("Panel", StylesList, "");
                StyleEntry.BLoadLayoutSnippet("StyleEntry");
                if (iStyle == itemStyle) {
                    StyleEntry.AddClass("Selected");
                } else {
                    StyleEntry.AddClass("Available");
                    if (IsCourier(unit)) {
                        StyleEntry.SetPanelEvent("onactivate", SwitchCourier(itemDef, iStyle));
                    } else if (Entities.IsWard(unit)) {
                        StyleEntry.SetPanelEvent("onactivate", SwitchWard(itemDef, iStyle));
                    } else {
                        StyleEntry.SetPanelEvent("onactivate", SwitchWearable(itemDef, iStyle));
                    }
                }
                if (AvailableStylesList
                    && AvailableStylesList[iStyle.toString()]
                    && AvailableStylesList[iStyle.toString()].name) {
                    let StyleLabel = StyleEntry.FindChildTraverse("StyleLabel");
                    StyleLabel.text = $.Localize(AvailableStylesList[iStyle.toString()].name)
                }
            }
            MultiStyle.SetPanelEvent("onactivate", ToggleStyleMenu(StyleMenu));
        }

        let TeamSelectorContainer = EconItemSlot.GetParent().FindChildTraverse("TeamSelectorContainer");
        if (TeamSelectorContainer) {
            if (EconItem.BHasClass("HasTeamSpecificViews")) {
                TeamSelectorContainer.SetHasClass("Hidden", false);
            } else {
                TeamSelectorContainer.SetHasClass("Hidden", true);
            }
        }
    })

    EconItem.SetPanelEvent("oncontextmenu", function () {
        let contextMenu = $.CreatePanel("ContextMenuScript", $.GetContextPanel(), "");
        contextMenu.AddClass("ContextMenu_NoArrow");
        contextMenu.AddClass("ContextMenu_NoBorder");
        contextMenu.GetContentsPanel().itemDef = itemDef;
        contextMenu.GetContentsPanel().itemStyle = itemStyle;
        contextMenu.GetContentsPanel().BLoadLayout("file://{resources}/layout/custom_game/econ_item_context_menu.xml", false, false);
        contextMenu.GetContentsPanel().SetFocus();
    })
}

// change key from slotName to slotIndex and sort
/*
SlotArray : [
	{
		"SlotName" : string,
		"SlotIndex" : string,
		"SlotText" : string,
			"DefaultItem" : string(itemDef),
			"ItemDefs" : { // available items
				i : string(itemdef)
				...
			}
	},
	...
]

*/
function SortSlots(AvailableItems) {
    let SlotArray = [];
    for (let slotName in AvailableItems) {
        let Slot = AvailableItems[slotName];
        Slot.SlotName = slotName;
        let slotIndex = Slot.SlotIndex;
        if (slotIndex === undefined) {
            continue;
        }
        let i = 0
        for (let i = 0; i < SlotArray.length; i++) {
            if (slotIndex < SlotArray[i].SlotIndex) {
                break;
            }
        }
        SlotArray.splice(i, 0, Slot);

    }
    return SlotArray;
}

function ToggleSelectCosmetics() {
    $('#SelectCosmeticsContainer').ToggleClass('CosmeticsContainerVisible');
    if (!$('#SelectCosmeticsContainer').BHasClass('CosmeticsContainerVisible')) {
        ResetCamera();
        let children = $("#HeroInspectBackground").Children();
        for (let child of children) {
            child.SetHasClass("Hidden", true);
        }
        $("#ToggleCosmeticsButon").SetHasClass("Activated", false);
        $("#ToggleCosmeticsButon").checked = false;
    } else {
        ZoomInCamera();
        let unit = Players.GetLocalPlayerPortraitUnit();
        let origin_unit = ID_Map[unit] || unit;

        let container = $("#UnitItemContainer" + origin_unit.toString());
        if (container === null) {
            CreateSelectCosmeticsForUnit(unit);
        } else {
            container.SetHasClass("Hidden", false);
        }
        $("#ToggleCosmeticsButon").SetHasClass("Activated", true);
        $("#ToggleCosmeticsButon").checked = true;
    }
}

function CloseSelectCosmetics() {
    $('#SelectCosmeticsContainer').SetHasClass('CosmeticsContainerVisible', false);
    let children = $("#HeroInspectBackground").Children();
    for (let child of children) {
        child.SetHasClass("Hidden", true);
    }
    $("#ToggleCosmeticsButon").SetHasClass("Activated", false);
    $("#ToggleCosmeticsButon").checked = false;
}

function ToggleStyleMenu(StyleMenu) {
    return function () {
        StyleMenu.ToggleClass("Hidden");
    }
}

function Taunt() {
    let unit = Players.GetLocalPlayerPortraitUnit();
    GameEvents.SendCustomGameEventToServer("Taunt", { "unit": unit });
}

function SelectAndLookUnit(unit) {
    $.Msg("SelectAndLookUnit");
    if (Entities.IsValidEntity(unit)) {
        let position = Entities.GetAbsOrigin(unit);
        GameUI.SelectUnit(unit, false);
        if (!ZoomInMode) {
            GameUI.SetCameraTargetPosition(position, 0.5);
        } else {
            // ZoomInCamera();
        }
    } else {
        $.Schedule(FRAME_TIME * 10, function () {
            SelectAndLookUnit(unit);
        })
    }
}

function AllyRemoved(data) {
    let unit = ID_Map[data.unit] || data.unit;
    let container = $("#UnitItemContainer" + unit.toString());
    if (container) {
        container.DeleteAsync(FRAME_TIME);
    }
    $("#Hero" + unit.toString()).DeleteAsync(FRAME_TIME);
}

function RemoveSelection() {
    let unit = Players.GetLocalPlayerPortraitUnit();
    GameEvents.SendCustomGameEventToServer("RemoveSelection", { "unit": unit });
}

function CopySelection() {
    let unit = Players.GetLocalPlayerPortraitUnit();
    GameEvents.SendCustomGameEventToServer("CopySelection", { "unit": unit });
}

function AllySpawned(data) {
    let unit = data.unit;
    if (Entities.IsValidEntity(unit)) {
        SelectAndLookUnit(unit);

        const HeroPanel = $.CreatePanel("Panel", $("#HeroImageContainer"), "Hero" + unit.toString());
        HeroPanel.AddClass("HeroImageItem");
        HeroPanel.SetPanelEvent("onactivate", () => {
            SelectAndLookUnit(unit);
        });

        const HeroImage = $.CreatePanel("DOTAHeroImage", HeroPanel, "HeroImage");
        HeroImage.AddClass("TopBarHeroImage");
        HeroImage.heroname = GetHeroName(unit);
        HeroImage.heroimagestyle = "landscape";

    } else {
        $.Schedule(FRAME_TIME * 10, function () {
            AllySpawned(data);
        })
    }
}

function GetEconItem(EconItemSlot) {
    let EconItem;
    for (let child of EconItemSlot.Children()) {
        if (child.paneltype == "DOTAEconItem") {
            EconItem = child;
        }
    }
    return EconItem
}

function UpdateWearable(params) {
    // $.Msg("UpdateWearable ", params);
    Game.EmitSound('inventory.wear');
    
    let unit_id = params.unit;
    unit_id = ID_Map[unit_id] || unit_id;
    let itemDef = params.itemDef;
    let slotName = params.slotName;
    let itemStyle = params.itemStyle;

    let container = $("#UnitItemContainer" + unit_id.toString());

    if (container) {
        let EquipContainer = container.FindChildTraverse("EquipItemContainer");
        let EconItemSlot = EquipContainer.FindChildTraverse(slotName);

        if (EconItemSlot) {
            let EconItem = GetEconItem(EconItemSlot);
            let StyleMenu = $("#" + EconItem.id + "StyleMenu");

            EconItem.DeleteAsync(0);
            if (StyleMenu) {
                StyleMenu.DeleteAsync(0);
            }

            let uid = GetUniqueID();
            const EconItemPanel = $.CreatePanelWithProperties("DOTAEconItem", EconItemSlot, uid, {itemdef: itemDef, itemstyle: itemStyle});
            EconItemPanel.AddClass("DisableInspect");
            EconItemPanel.SetPanelEvent("onload", () => {
                SetEconItemButtons(uid, itemDef, itemStyle);
            });
        }
    }
}

function RespawnWear(data) {
    $.Msg("RespawnWear ", data);
    let old_unit = data.old_unit;
    let new_unit = data.new_unit;
    let item = data.item;
    let bundle = data.bundle;

    ID_Map[new_unit] = old_unit;
    SelectAndLookUnit(new_unit);

    let HeroImagePanel = $("#Hero" + old_unit.toString());

    HeroImagePanel.SetPanelEvent("onactivate", function () {
        SelectAndLookUnit(new_unit);
    });

    if (bundle) {
        for (let i in bundle) {
            let subItem = bundle[i];
            UpdateWearable(subItem);
        }
    } else {
        UpdateWearable(item);
    }
}

function OnSelectionChangeForCosmetics(unit, old_unit) {
    if ($('#SelectCosmeticsContainer').BHasClass('CosmeticsContainerVisible')) {
        if (old_unit) {
            let originID = ID_Map[old_unit] || old_unit;
            let CurrentCosmeticsContainer = $("#UnitItemContainer" + originID.toString());
            if (CurrentCosmeticsContainer) {
                CurrentCosmeticsContainer.SetHasClass("Hidden", true);
            }
        }

        let originID = ID_Map[unit] || unit;
        let CosmeticsContainer = $("#UnitItemContainer" + originID.toString());

        if (CosmeticsContainer === null) {
            CreateSelectCosmeticsForUnit(unit);
        } else {
            CosmeticsContainer.SetHasClass("Hidden", false);
        }
        ZoomInCamera();
    }

}

function CreateRespawnTooltip() {
    let RespawnTooltip = $.CreatePanel("Panel", $.GetContextPanel(), "RespawnTooltip");
    RespawnTooltip.BLoadLayout("file://{resources}/layout/custom_game/respawn_tooltip.xml", false, false);
    RespawnTooltip.SetHasClass("Hidden", true);
}

function ToggleTutorial() {
    if ($("#TutorialPanel").BHasClass("TutorialVisible")) {
        Game.EmitSound('panorama.logo_rollover');
        $("#TutorialVideo").SetURL("about:blank");
    } else {
        Game.EmitSound('panorama.logo_rolloff');
        $("#TutorialVideo").SetURL("https://www.bilibili.com/video/av48342518/");
    }
    $("#TutorialPanel").ToggleClass("TutorialVisible");
}

function SwitchTinyModel(modelIndex) {
    let unit = Players.GetLocalPlayerPortraitUnit();
    GameEvents.SendCustomGameEventToServer("SwitchTinyModel", { "unit": unit, "model_index": modelIndex});
}

(function () {
    MAX_SLOT = 10;

    $.RegisterEventHandler('DOTAUIHeroPickerHeroSelected', $('#SelectEnemyHeroContainer'), SpawnEnemyNewHero);
    $.RegisterEventHandler('DOTAUIHeroPickerHeroSelected', $('#SelectAllyHeroContainer'), SpawnAllyNewHero);
    GameEvents.Subscribe('UpdateWearable', UpdateWearable);
    GameEvents.Subscribe('AllySpawned', AllySpawned);
    GameEvents.Subscribe('AllyRemoved', AllyRemoved);
    GameEvents.Subscribe('RespawnWear', RespawnWear);
    
    CreateRespawnTooltip()
    
    ID_Map = {};
    
    $('#SelectAllyHeroContainer').SetHasClass("HeroPickerVisible", true);
    
    GetUniqueID = UniqueIDClosure();
    RegisterSelectionChange(OnSelectionChangeForCosmetics);
    
})();

