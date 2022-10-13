"use strict";

function DismissMenu()
{
	$.DispatchEvent( "DismissAllContextMenus" );
}

function ShowItemDetail() {
    var itemDef = $.GetContextPanel().itemDef;
    var itemStyle = $.GetContextPanel().itemStyle;
    $.DispatchEvent("DOTAShowStoreItemDetailsPage", -1, parseInt(itemDef), parseInt(itemStyle));
    DismissMenu();
}