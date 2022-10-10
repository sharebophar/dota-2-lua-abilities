dresser = class({})

function dresser:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}

	return funcs
end

function dresser:CheckState()
	local state = {
        [MODIFIER_STATE_FLYING] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	return state
end

function dresser:GetVisualZDelta()

	return 800
end

function dresser:OnCreated( kv )
    -- print(self:GetParent())
    if IsServer() then
        for k,v in pairs(self:GetParent():GetChildren()) do
            if v:GetClassname() == "dota_item_wearable" then
                v:RemoveSelf()
            end
        end
    end
end

function dresser:GetAbsoluteNoDamageMagical( params )
	return 1
end

function dresser:GetAbsoluteNoDamagePhysical( params )
	return 1
end

function dresser:GetAbsoluteNoDamagePure( params )
	return 1
end