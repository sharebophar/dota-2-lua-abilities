flying = class({})

function flying:DeclareFunctions()
	local funcs = {
	}

	return funcs
end

function flying:CheckState()
	local state = {
        [MODIFIER_STATE_FLYING] = true,
	}

	return state
end

-- function flying:GetVisualZDelta()

-- 	return 800
-- end

-- function flying:OnCreated( kv )
--     -- print(self:GetParent())
--     if IsServer() then
--     end
-- end