
function SortPage(Page) {
    var PageArray = [];
    for (var pi in Page) {
        var Com = Page[pi];
        PageArray.push(Com);
    }
    PageArray.sort(keysort("votes", false));
    return PageArray;
}

function SetRankItemStyle(econItemID, itemDef, itemStyle) {
    var EconItem = $("#" + econItemID);
    var RankEconItemSlot = EconItem.GetParent();
    var slotName = RankEconItemSlot.id;
    var MultiStyle = EconItem.FindChildTraverse("MultiStyle");
    if (MultiStyle.visible) {
        var RankMultiStyle = $.CreatePanel("Panel", RankEconItemSlot, "RankMultiStyle");
        var RankMultiStyleIcon = $.CreatePanel("Panel", RankMultiStyle, "RankMultiStyleIcon");
        var RankSelectStyle = $.CreatePanel("Label", RankMultiStyle, "RankSelectStyle");

        var unit = Players.GetLocalPlayerPortraitUnit();
        var AvailableItems = CustomNetTables.GetTableValue("hero_available_items", GetUnitName(unit));

        var SelectStyle = MultiStyle.FindChildTraverse("MultiStyleSelectedStyle");
        var total = SelectStyle.text.split('/')[1];
        RankSelectStyle.text = (parseInt(itemStyle) + 1).toString() + "/" + total;

        if (!itemStyle) {
            itemStyle = "0";
        }

        MultiStyle.DeleteAsync(FRAME_TIME);

        var EconItemIcon = EconItem.FindChildTraverse("EconItemIcon");
        if (AvailableItems && AvailableItems[slotName] && AvailableItems[slotName]["styles"]
            && AvailableItems[slotName]["styles"][itemDef] && AvailableItems[slotName]["styles"][itemDef][itemStyle.toString()]
            && AvailableItems[slotName]["styles"][itemDef][itemStyle.toString()].icon_path) {

            var imageSrc = "s2r://panorama/images/" + AvailableItems[slotName]["styles"][itemDef][itemStyle.toString()].icon_path + "_png.vtex";
            EconItemIcon.SetImage(imageSrc);
        }
    }
}

function SubmitComment() {
    var CommentTextEntry = $("#CommentTextEntry");
    var comID = CommentTextEntry.comID;
    var content = CommentTextEntry.text;
    CommentTextEntry.text = "";
    SendEventToServerWithCallback(
        "SubmitComment",
        { "combinationID": comID, "content": content },
        function (params) {
            $.Msg(params);
            var result = JSON.parse(params);
            if (result.success) {
                Game.EmitSound('Tutorial.Notice.Speech');
                ShowComment(comID)();
                var msg = { "text": "CommentSucceed", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
            } else {
                Game.EmitSound('General.Cancel');
                var msg = { "text": "CommentFailed", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
            }
        }
    )
}

function CommendComment(commentID) {
    return function () {
        SendEventToServerWithCallback(
            "CommendComment",
            { "commentID": commentID },
            function (params) {
                $.Msg(params);
                var result = JSON.parse(params);
                if (result.success) {
                    Game.EmitSound('dungeon.plus_one');
                    var RecentComment = $("#RecentComments").FindChildTraverse("Comment" + commentID.toString());
                    $.Msg(RecentComment);
                    if (RecentComment) {
                        var commendCommentNum = parseInt(RecentComment.FindChildTraverse("CommendCommentNum").text);
                        RecentComment.FindChildTraverse("CommendCommentNum").text = commendCommentNum + 1;
                        RecentComment.SetHasClass("Voted", true);
                    }
                    var GoodComment = $("#GoodComments").FindChildTraverse("Comment" + commentID.toString());
                    $.Msg(GoodComment);
                    if (GoodComment) {
                        var commendCommentNum = parseInt(GoodComment.FindChildTraverse("CommendCommentNum").text);
                        GoodComment.FindChildTraverse("CommendCommentNum").text = commendCommentNum + 1;
                        GoodComment.SetHasClass("Voted", true);
                    }
                    var msg = { "text": "CommendSucceed", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                    GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
                } else {
                    Game.EmitSound('ui.treasure_remove_hero');
                    var RecentComment = $("#RecentComments").FindChildTraverse("Comment" + commentID.toString());
                    if (RecentComment) {
                        var commendCommentNum = parseInt(RecentComment.FindChildTraverse("CommendCommentNum").text);
                        RecentComment.FindChildTraverse("CommendCommentNum").text = commendCommentNum - 1;
                        RecentComment.SetHasClass("Voted", false);
                    }
                    var GoodComment = $("#GoodComments").FindChildTraverse("Comment" + commentID.toString());
                    if (GoodComment) {
                        var commendCommentNum = parseInt(GoodComment.FindChildTraverse("CommendCommentNum").text);
                        GoodComment.FindChildTraverse("CommendCommentNum").text = commendCommentNum - 1;
                        GoodComment.SetHasClass("Voted", false);
                    }
                    var msg = { "text": "CommendCancle", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                    GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
                }
            }
        );
    };
}

function LoadMoreComments() {
    var comID = $("#CommentTextEntry").comID;
    var RecentCommentsPanel = $("#RecentComments");
    var start = RecentCommentsPanel.Children().length - 2;

    var LoadMore = RecentCommentsPanel.FindChildTraverse("LoadMore");
    LoadMore.SetHasClass("Pending", true);

    Game.EmitSound('economy.plink_ball_launch');

    SendEventToServerWithCallback(
        "LoadMoreComments",
        { "combinationID": comID, "start": start },
        function (params) {
            // $.Msg(params);
            var Comments = params.comments;
            var CommentPanel = null;

            for (var i in Comments) {
                var Comment = Comments[i];
                CommentPanel = $.CreatePanel("Panel", RecentCommentsPanel, "Comment" + Comment.commentID.toString());
                CommentPanel.BLoadLayoutSnippet("Comment");
                CommentPanel.SetDialogVariable("comment", Comment.content);
                var timestamp = parseInt(Comment.timestamp / 1000);
                CommentPanel.SetDialogVariableTime("timestamp", timestamp);
                CommentPanel.FindChildTraverse("CommentAvatarImage").accountid = Comment.steamID;
                CommentPanel.FindChildTraverse("UserName").accountid = Comment.steamID;
                CommentPanel.FindChildTraverse("CommendCommentNum").text = Comment.commends;
                CommentPanel.FindChildTraverse("CommendCommentButton").SetPanelEvent("onactivate", CommendComment(Comment.commentID));
                if (Comment.voted) {
                    CommentPanel.SetHasClass("Voted", true);
                }
            }

            LoadMore.SetHasClass("Pending", false);
            if (LoadMore && CommentPanel) {
                RecentCommentsPanel.MoveChildAfter(LoadMore, CommentPanel);
            }
        }
    )
}

function ShowComment(comID) {
    return function () {
        $("#CommentPanel").SetHasClass("CommentsStatusLoading", true);
        SendEventToServerWithCallback(
            "RequestComments",
            { "combinationID": comID },
            function (params) {
                // $.Msg(params);
                $("#CommentPanel").SetHasClass("CommentsStatusLoading", false);
                var Comments = params.comments;

                var GoodComments = Comments.GoodComments;
                var GoodCommentsPanel = $("#GoodComments");
                for (var i in GoodComments) {
                    var Comment = GoodComments[i];
                    var CommentPanel = $.CreatePanel("Panel", GoodCommentsPanel, "Comment" + Comment.commentID.toString());
                    CommentPanel.BLoadLayoutSnippet("Comment");
                    CommentPanel.SetDialogVariable("comment", Comment.content);
                    var timestamp = parseInt(Comment.timestamp / 1000);
                    CommentPanel.SetDialogVariableTime("timestamp", timestamp);
                    CommentPanel.FindChildTraverse("CommentAvatarImage").accountid = Comment.steamID;
                    CommentPanel.FindChildTraverse("UserName").accountid = Comment.steamID;
                    CommentPanel.FindChildTraverse("CommendCommentNum").text = Comment.commends;
                    CommentPanel.FindChildTraverse("CommendCommentButton").SetPanelEvent("onactivate", CommendComment(Comment.commentID));
                    if (Comment.voted) {
                        CommentPanel.SetHasClass("Voted", true);
                    }
                }

                var RecentComments = Comments.RecentComments;
                var CommentPanel = null;
                var RecentCommentsPanel = $("#RecentComments");
                for (var i in RecentComments) {
                    var Comment = RecentComments[i];
                    CommentPanel = $.CreatePanel("Panel", RecentCommentsPanel, "Comment" + Comment.commentID.toString());
                    CommentPanel.BLoadLayoutSnippet("Comment");
                    CommentPanel.SetDialogVariable("comment", Comment.content);
                    var timestamp = parseInt(Comment.timestamp / 1000);
                    CommentPanel.SetDialogVariableTime("timestamp", timestamp);
                    CommentPanel.FindChildTraverse("CommentAvatarImage").accountid = Comment.steamID;
                    CommentPanel.FindChildTraverse("UserName").accountid = Comment.steamID;
                    CommentPanel.FindChildTraverse("CommendCommentNum").text = Comment.commends;
                    CommentPanel.FindChildTraverse("CommendCommentButton").SetPanelEvent("onactivate", CommendComment(Comment.commentID));
                    if (Comment.voted) {
                        CommentPanel.SetHasClass("Voted", true);
                    }
                }
                var LoadMore = RecentCommentsPanel.FindChildTraverse("LoadMore");
                if (LoadMore && CommentPanel) {
                    RecentCommentsPanel.MoveChildAfter(LoadMore, CommentPanel);
                }
            }
        );

        Game.EmitSound('panorama.panorama_hero_hat_select');
        var CombinationRankPanel = $("#CombinationRankPanel");
        CombinationRankPanel.SetHasClass("CommentPanelVisible", true);

        var CommentHeaderEconItems = $("#CommentHeaderEconItems");

        var OriginComRow = $("#Combination" + comID.toString());
        var OriginComEconItems = OriginComRow.FindChildTraverse("ComEconItems");
        var OriginRankEconItemSlots = OriginComEconItems.FindChildrenWithClassTraverse("RankEconItemSlot");

        for (var Child of CommentHeaderEconItems.Children()) {
            Child.DeleteAsync(FRAME_TIME);
        }

        for (var Comment of $("#GoodComments").FindChildrenWithClassTraverse("Comment")) {
            Comment.DeleteAsync(FRAME_TIME);
        }

        for (var Comment of $("#RecentComments").FindChildrenWithClassTraverse("Comment")) {
            Comment.DeleteAsync(FRAME_TIME);
        }

        for (var Child of OriginRankEconItemSlots) {
            var itemDef = Child.itemDef;
            var itemStyle = Child.itemStyle;
            var uid = GetUniqueID();
            var slotName = Child.id;
            var RankEconItemSlot = $.CreatePanel("Panel", CommentHeaderEconItems, slotName);
            RankEconItemSlot.AddClass("RankEconItemSlot");

            const EconItemPanel = $.CreatePanelWithProperties("DOTAEconItem", RankEconItemSlot, uid, {itemdef: itemDef});
            EconItemPanel.AddClass("DisableInspect");
            EconItemPanel.SetPanelEvent("onload", () => {
                SetRankItemStyle(uid, itemDef, itemStyle);
            });
        }
        CommentHeaderEconItems.SetPanelEvent("onactivate", WearCombination(comID));

        $("#CommentTextEntry").comID = comID;
    }
}

function CreatePage(heroName, Page) {
    var ComRow = null;

    var UnitRank = $("#CombinationRank" + heroName);
    if (UnitRank == null) {
        UnitRank = $.CreatePanel("Panel", $("#CombinationRankPanel"), "CombinationRank" + heroName);
        UnitRank.AddClass("CombinationRank");
        UnitRank.page = 1;
        CurrentUnitRank = UnitRank;
        UnitRank.SetHasClass("Hidden", false);
    } else {
        UnitRank.page = UnitRank.page + 1;
    }

    var unitName = heroName.substring(0, 9) + "unit" + heroName.substring(13);
    var AvailableItems = CustomNetTables.GetTableValue("hero_available_items", unitName);
    var SlotArray = SortSlots(AvailableItems);
    var PageArray = SortPage(Page);
    $.Msg(Page);
    $.Msg(PageArray);
    for (var ci in PageArray) {
        $.Msg(ci);
        var Com = PageArray[ci];
        var comID = Com.combinationID;
        ComRow = $.CreatePanel("Panel", UnitRank, "Combination" + comID.toString());
        ComRow.AddClass("CombinationRow");
        if (CurrentVoted[heroName] == comID) {
            ComRow.AddClass("Voted");
        }

        var ComLeftPanel = $.CreatePanel("Panel", ComRow, "ComLeftPanel");
        var ComCreator = $.CreatePanel("DOTAAvatarImage", ComLeftPanel, "ComCreator");
        ComCreator.style.width = "80%";
        ComCreator.style.height = "40%";
        ComCreator.style["tooltip-position"] = "left";
        ComCreator.accountid = Com.creator;
        ComCreator.AddClass("ComCreator");
        var ComRankNum = $.CreatePanel("Panel", ComLeftPanel, "ComRankNum");
        var ComRankNumLabel = $.CreatePanel("Label", ComRankNum, "ComRankNumLabel");
        ComRankNumLabel.text = parseInt(ci) + 1 + (parseInt(UnitRank.page) - 1) * MAX_SLOT;


        var ComEconItems = $.CreatePanel("Panel", ComRow, "ComEconItems");
        ComEconItems.AddClass("CombinationEconItems");
        for (var iSlotArray = 0; iSlotArray < MAX_SLOT; iSlotArray++) {
            var Slot = SlotArray[iSlotArray];
            if (!Slot) {
                continue;
            }
            var slotIndex = Slot.SlotIndex;
            var itemDef = Com["itemDef" + slotIndex];
            if (itemDef == 0 || Slot.DisplayInLoadout == 0) {
                continue;
            }
            var itemStyle = Com["style" + slotIndex];
            var uid = GetUniqueID();
            var slotName = Slot.SlotName;
            var RankEconItemSlot = $.CreatePanel("Panel", ComEconItems, slotName);
            RankEconItemSlot.AddClass("RankEconItemSlot");
            RankEconItemSlot.itemDef = itemDef;
            RankEconItemSlot.itemStyle = itemStyle;

            const EconItemPanel = $.CreatePanelWithProperties("DOTAEconItem", RankEconItemSlot, uid, {itemdef: itemDef, itemstyle:itemStyle});
            EconItemPanel.AddClass("DisableInspect");
            EconItemPanel.SetPanelEvent("onload", () => {
                SetRankItemStyle(uid, itemDef, itemStyle);
            });
        }
        ComEconItems.SetPanelEvent("onactivate", WearCombination(comID));
        var CombinationVotePanel = $.CreatePanel("Panel", ComRow, "CombinationVotePanel");
        CombinationVotePanel.BLoadLayoutSnippet("CombinationVotePanel");
        var VoteNumLabel = CombinationVotePanel.FindChildTraverse("VoteNum");
        VoteNumLabel.text = parseInt(Com["votes"]);
        var CommentNumLabel = CombinationVotePanel.FindChildTraverse("CommentNum");
        CommentNumLabel.text = parseInt(Com["comments"]);
        var VoteUpButton = CombinationVotePanel.FindChildTraverse("VoteUpButton");
        VoteUpButton.SetPanelEvent("onactivate", VoteCombination(heroName, comID));
        var CommentButton = CombinationVotePanel.FindChildTraverse("CommentButton");
        CommentButton.SetPanelEvent("onactivate", ShowComment(comID));
    }
    var LoadMore = UnitRank.FindChildTraverse("LoadMore");
    if (LoadMore) {
        if (Object.keys(Page).length > 0) {
            UnitRank.MoveChildAfter(LoadMore, ComRow);
        } else {
            var msg = { "text": "NoMore", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
            GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
        }
    } else {
        LoadMore = $.CreatePanel("Panel", UnitRank, "LoadMore");
        LoadMore.BLoadLayoutSnippet("LoadMore");
        LoadMore.AddClass("LoadMore");
        LoadMore.SetPanelEvent("onactivate", LoadMoreCombination(heroName));
    }
}

function LoadMoreCombination(heroName) {
    return function () {
        Game.EmitSound('economy.plink_ball_launch');
        var UnitRank = $("#CombinationRank" + heroName);
        var page = UnitRank.page;
        var LoadMore = UnitRank.FindChildTraverse("LoadMore");
        LoadMore.SetHasClass("Pending", true);
        SendEventToServerWithCallback(
            "RequestCombination",
            { "hero_name": heroName, "page": page + 1 },
            function (params) {
                var Page = params.page;
                LoadMore.SetHasClass("Pending", false);
                CreatePage(heroName, Page);
            }
        )
    }
}

function ToggleCombinationRank() {
    var unit = Players.GetLocalPlayerPortraitUnit();
    var unitName = GetUnitName(unit)

    if ($("#CombinationRankPanel").BHasClass("RankPanelVisible")) {
        // 排行榜打开中
        Game.EmitSound('panorama.today_rollover');
        $("#CombinationRankPanel").SetHasClass("RankPanelVisible", false);
        $('#CombinationRankPanel').SetHasClass('CommentPanelVisible', false);
        if (CurrentUnitRank) {
            CurrentUnitRank.SetHasClass("Hidden", true);
        }
        CurrentUnitRank = null;
    } else {
        if (IsWearableUnit(unit)) {
            // 确认是换装英雄才有排行榜
            Game.EmitSound('panorama.today_rolloff');
            var heroName = unitName.substring(0, 9) + "hero" + unitName.substring(13);
            var UnitRank = $("#CombinationRank" + heroName);
            if (UnitRank) {
                // 创建过该英雄的排行榜
                $("#CombinationRankPanel").SetHasClass("RankPanelVisible", true);
                UnitRank.SetHasClass("Hidden", false);
                CurrentUnitRank = UnitRank;
            } else {
                // 没创建过，请求数据
                $("#CombinationRankPanel").SetHasClass("RankPanelVisible", true);
                $("#CombinationRankPanel").SetHasClass("Loading", true);
                SendEventToServerWithCallback(
                    "RequestCombination",
                    { "hero_name": heroName, "page": 1 },
                    function (params) {
                        $("#CombinationRankPanel").SetHasClass("Loading", false);
                        var Page = params.page;
                        CreatePage(heroName, Page);
                    }
                )
            }
        } else {
            Game.EmitSound('General.Cancel');
            var msg = { "text": "PleaseSelectAllyHero", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
            GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
        }
    }
}

function Vote() {
    var unit = Players.GetLocalPlayerPortraitUnit();
    var unitName = GetUnitName(unit);
    if (IsWearableUnit(unit)) {
        SendEventToServerWithCallback(
            "Vote",
            { "unit": unit },
            function (params) {
                var result = JSON.parse(params);
                if (result.success) {
                    Game.EmitSound('ui.replay_dn_complete');
                    var heroName = unitName.substring(0, 9) + "hero" + unitName.substring(13);
                    var comID = result.combinationID;
                    RefreshCombinationRank(heroName);
                    if (result.bExist) {
                        var msg = { "text": "CombinationExist", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                        GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
                    } else {
                        var msg = { "text": "CombinationNotExist", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                        GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
                    }
                    CurrentVoted[heroName] = comID;
                } else {
                    Game.EmitSound('General.Cancel');
                    var msg = { "text": "VoteFailed", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                    GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
                }
            }
        )
    }
}

function VoteCombination(heroName, comID) {
    return function () {
        SendEventToServerWithCallback(
            "VoteCombination",
            { "combinationID": comID },
            function (params) {
                var result = JSON.parse(params);
                if (result.success) {
                    Game.EmitSound('dungeon.plus_one');
                    RefreshCombinationRank(heroName);
                    var msg = { "text": "VoteSucceed", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                    GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
                    CurrentVoted[heroName] = comID;
                } else {
                    Game.EmitSound('General.Cancel');
                    var msg = { "text": "VoteFailed", "duration": 3, "style": { "color": "white", "font-size": "30px", "background-color": "rgb(136, 34, 34)", "opacity": "0.5" } };
                    GameEvents.SendCustomGameEventToAllClients("bottom_notification", msg);
                }
            }
        )
    }
}

function WearCombination(comID) {
    return function () {
        var unit = Players.GetLocalPlayerPortraitUnit();
        SendEventToServerWithCallback(
            "WearCombination",
            { "unit": unit, "combinationID": comID },
            function (params) {
                // $.Msg(params);
                var ComRow = $("#Combination" + comID.toString());
                // ComRow.SetHasClass("Selected", true);
            }
        )
    }
}

function RefreshCombinationRank(heroName) {
    var UnitRank = $("#CombinationRank" + heroName);
    if (UnitRank) {
        // 排行榜已存在
        $.Schedule(2 * FRAME_TIME, function () {
            SendEventToServerWithCallback(
                "RequestCombination",
                { "hero_name": heroName, "page": 1 },
                function (params) {
                    var ComRows = UnitRank.FindChildrenWithClassTraverse("CombinationRow");
                    for (var ComRow of ComRows) {
                        ComRow.DeleteAsync(FRAME_TIME);
                    }
                    var Page = params.page;
                    UnitRank.page = 0;
                    CreatePage(heroName, Page);
                }
            )
        })
    }
}

function CacheCurrentVoted(params) {
    var heroName = params.hero_name;
    var comID = params.combinationID;
    CurrentVoted[heroName] = comID;
}

function OnSelectionChangeForRank(unit, old_unit) {
    if ($("#CombinationRankPanel").BHasClass("RankPanelVisible")) {
        // 排行榜打开中
        var oldHeroName = CurrentUnitRank.id.substring(15);
        var unitName = GetUnitName(unit)
        if (IsWearableUnit(unit)) {
            var heroName = unitName.substring(0, 9) + "hero" + unitName.substring(13);
            if (heroName != oldHeroName) {
                // 换英雄了，关闭排行榜
                Game.EmitSound('panorama.today_rollover');
                $("#CombinationRankPanel").SetHasClass("RankPanelVisible", false);
                if (CurrentUnitRank) {
                    CurrentUnitRank.SetHasClass("Hidden", true);
                }
                $('#CombinationRankPanel').SetHasClass('CommentPanelVisible', false);
                CurrentUnitRank = null;
            }
        } else {
            // 不是换装英雄，关闭排行榜
            Game.EmitSound('panorama.today_rollover');
            $("#CombinationRankPanel").SetHasClass("RankPanelVisible", false);
            $('#CombinationRankPanel').SetHasClass('CommentPanelVisible', false);
            if (CurrentUnitRank) {
                CurrentUnitRank.SetHasClass("Hidden", true);
            }
            CurrentUnitRank = null;
        }
    }
}

function BackToRank() {
    Game.EmitSound('ui.click_back');
    $('#CombinationRankPanel').SetHasClass('CommentPanelVisible', false);
}

(function () {
    MAX_SLOT = 10;

    GameEvents.Subscribe('CacheCurrentVoted', CacheCurrentVoted);

    CurrentUnitRank = null;
    CurrentVoted = {};

    $("#CommentTextEntry").SetMaxChars(300);

    GetUniqueID = UniqueIDClosure();
    RegisterSelectionChange(OnSelectionChangeForRank);
})();