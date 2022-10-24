phoenix_sun_ray_toggle_move_lua = class({})

function phoenix_sun_ray_toggle_move_lua:IsHiddenWhenStolen() 		return false end
function phoenix_sun_ray_toggle_move_lua:IsRefreshable() 			return true end
function phoenix_sun_ray_toggle_move_lua:IsStealable() 			return false end
function phoenix_sun_ray_toggle_move_lua:IsNetherWardStealable() 	return false end
function phoenix_sun_ray_toggle_move_lua:ProcsMagicStick() return false end
-- function phoenix_sun_ray_toggle_move_lua:GetAssociatedPrimaryAbilities() return "imba_phoenix_sun_ray" end

function phoenix_sun_ray_toggle_move_lua:GetAbilityTextureName()   return "phoenix_sun_ray_toggle_move" end

-- 并不是一个toggle技能，所以得自己实现开关
function phoenix_sun_ray_toggle_move_lua:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    caster.sun_ray_is_moving = not caster.sun_ray_is_moving
end