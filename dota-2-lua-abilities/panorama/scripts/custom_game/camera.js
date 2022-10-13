
function RotatePoint(Point, Center, angle) {
	var vector = [Point[0] - Center[0], Point[1] - Center[1]];
	var radian = angle / 180 * Math.PI;
	var cosA = Math.cos(radian);
	var sinA = Math.sin(radian);
	var x = vector[0] * cosA - vector[1] * sinA + Center[0];
	var y = vector[0] * sinA + vector[1] * cosA + Center[1];
	return [x, y, Center[2]];
}


function ResetCamera() {
	CamerPitch = 60;
	GameUI.SetCameraPitchMin(CamerPitch);
	GameUI.SetCameraPitchMax(CamerPitch);

	CamerYaw = 0
	GameUI.SetCameraYaw(CamerYaw);
	GameUI.SetCameraDistance(1134);
	GameUI.SetCameraLookAtPositionHeightOffset(0);
	// GameEvents.SendCustomGameEventToServer("SendToConsole", { "command": "dota_camera_edgemove 1" });

	ZoomInMode = false;
}

function ZoomInCamera() {
	$.Msg("ZoomIn");
	var unit = Players.GetLocalPlayerPortraitUnit();
	var forward = Entities.GetForward(unit);
	if (!forward) {
		return;
    }
    
    Game.EmitSound('ui.herochallenge_complete');
	CamerPitch = 15
	GameUI.SetCameraPitchMin(CamerPitch);
	GameUI.SetCameraPitchMax(CamerPitch);

	var yaw = forward2yaw(forward);
	CamerYaw = yaw;
	GameUI.SetCameraYaw(CamerYaw);

	GameUI.SetCameraTarget(unit);
	GameUI.SetCameraTarget(-1);

	var position = Entities.GetAbsOrigin(unit);
	var right = Entities.GetRight(unit);
	var cameraOffset = CAMERA_OFFSET_RATIO * CameraDistance;
	var x = position[0] - right[0] * cameraOffset;
	var y = position[1] - right[1] * cameraOffset;
	var z = position[2];
	if (Entities.GetUnitName(unit) == "npc_dota_hero_wisp") {
		z -= 150;
	}
	// $.Msg(Entities.GetUnitName(unit), position, ' ', right, ' ', x, ' ', y);

	CamerPosition = [x, y, z];
	GameUI.SetCameraTargetPosition(CamerPosition, 0.5);
	GameUI.SetCameraDistance(CameraDistance);
	if (z > 450) {
		GameUI.SetCameraLookAtPositionHeightOffset((z - 450) * 1.5 + CameraHeight);
	} else {
		GameUI.SetCameraLookAtPositionHeightOffset(CameraHeight);
	}
	GameUI.SetCameraTerrainAdjustmentEnabled(false);

	// GameEvents.SendCustomGameEventToServer("SendToConsole", { "command": "dota_camera_edgemove 0" });

	ZoomInMode = true;
}


function UpdateCamera() {

	if (Draging) {
		if (GameUI.IsMouseDown(0)) {
			if (ZoomInMode) {
				var CursorPosition = GameUI.GetCursorPosition();
				if (CursorPosition[0] != DragCursor[0]) {
					var diff = (DragCursor[0] - CursorPosition[0]) * 0.2;
					CamerYaw = diff + CamerYaw;
					GameUI.SetCameraYaw(CamerYaw);

					var unit = Players.GetLocalPlayerPortraitUnit();
					var unitPosition = Entities.GetAbsOrigin(unit);

					CamerPosition = RotatePoint(CamerPosition, unitPosition, diff);
					GameUI.SetCameraTargetPosition(CamerPosition, -1);
				}

				if (CursorPosition[1] != DragCursor[1]) {
					var diff = (CursorPosition[1] - DragCursor[1]) * 0.2
					CamerPitch = diff + CamerPitch;
					CamerPitch = Math.max(CamerPitch, 1);
					CamerPitch = Math.min(CamerPitch, 90);
					GameUI.SetCameraPitchMin(CamerPitch);
					GameUI.SetCameraPitchMax(CamerPitch);
				}

				DragCursor[0] = CursorPosition[0];
				DragCursor[1] = CursorPosition[1];
			}
		} else {
			Draging = false;
		}
	} else {
		if (CameraHeight != $("#CameraHeightSlider").value) {
			var HeightOffset = GameUI.GetCameraLookAtPositionHeightOffset();
			var difference = $("#CameraHeightSlider").value - CameraHeight;
			if (ZoomInMode) {
				GameUI.SetCameraLookAtPositionHeightOffset(HeightOffset + difference);
			}
			CameraHeight = $("#CameraHeightSlider").value;

			$("#CameraHeightValue").text = parseInt(CameraHeight);
		}

		if (CameraDistance != $("#CameraDistanceSlider").value) {
			if (ZoomInMode) {
				GameUI.SetCameraDistance(CameraDistance)
			}
			var newDistance = $("#CameraDistanceSlider").value;

			if (ZoomInMode) {
				var unit = Players.GetLocalPlayerPortraitUnit();
				var position = Entities.GetAbsOrigin(unit);
				CamerPosition[0] = (CamerPosition[0] - position[0]) / CameraDistance * newDistance + position[0];
				CamerPosition[1] = (CamerPosition[1] - position[1]) / CameraDistance * newDistance + position[1];
				GameUI.SetCameraTargetPosition(CamerPosition, -1);
			}

			CameraDistance = newDistance;
			$("#CameraDistanceValue").text = parseInt(CameraDistance);
		}
	}


	$.Schedule(FRAME_TIME, UpdateCamera);
}

function InitCamera() {
	CAMERA_OFFSET_RATIO = 0.18;

	ZoomInMode = false;

	CameraHeight = 0;

	$("#CameraHeightSlider").max = 300;
	$("#CameraHeightSlider").min = -300;
	$("#CameraHeightSlider").value = CameraHeight;
	$("#CameraHeightValue").text = parseInt(CameraHeight);
	$("#CameraHeightSlider").SetShowDefaultValue(true);

	CameraDistance = 500;
	$("#CameraDistanceSlider").max = 1000;
	$("#CameraDistanceSlider").min = 1;
	$("#CameraDistanceSlider").value = CameraDistance;
	$("#CameraDistanceValue").text = parseInt(CameraDistance);
	$("#CameraDistanceSlider").SetShowDefaultValue(true);

	CamerYaw = 0;
	CamerPitch = 60;
	CamerPosition = null;

	Draging = false;
	DragCursor = GameUI.GetCursorPosition();

    UpdateCamera();
}


function MouseFilter(event, click) {
	// $.Msg(event);
    // $.Msg(click);
    // $.Msg(ZoomInMode);

	if (event == "pressed" && click == 0 && ZoomInMode) {
		Draging = true;
		DragCursor = GameUI.GetCursorPosition();
		return true;
    }
    
    // if (event == "wheeled" && ZoomInMode) {
    //     $.Msg("return true");
    //     return false;
    // }
}

(function () {
	FRAME_TIME = 1 / 30;
	InitCamera();
	GameUI.SetMouseCallback(MouseFilter);
})();