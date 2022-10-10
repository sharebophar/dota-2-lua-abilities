no_health_bar = class({})

function no_health_bar:CheckState()
	local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}

	return state
end