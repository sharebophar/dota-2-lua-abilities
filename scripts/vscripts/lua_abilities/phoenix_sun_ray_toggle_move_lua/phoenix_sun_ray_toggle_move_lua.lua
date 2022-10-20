phoenix_sun_ray_toggle_move_lua = class({})

-- 并不是一个toggle技能，所以得自己实现开关
function phoenix_sun_ray_toggle_move_lua:OnSpellStart()
    self.can_move = not self.can_move
end

function phoenix_sun_ray_toggle_move_lua:IsToggleMove()
    return self.can_move
end

function phoenix_sun_ray_toggle_move_lua:OnUpgrade()
    self.can_move = false
end

function phoenix_sun_ray_toggle_move_lua:ResetToggleMove()
    self.can_move = false
end