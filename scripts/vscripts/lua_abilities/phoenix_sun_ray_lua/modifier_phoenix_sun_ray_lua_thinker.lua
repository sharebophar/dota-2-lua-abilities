modifier_phoenix_sun_ray_lua_thinker = modifier_phoenix_sun_ray_lua_thinker or class({})

function modifier_phoenix_sun_ray_lua_thinker:IsDebuff()				return false end
function modifier_phoenix_sun_ray_lua_thinker:IsHidden() 				return true end
function modifier_phoenix_sun_ray_lua_thinker:IsPurgable() 				return false end
function modifier_phoenix_sun_ray_lua_thinker:IsPurgeException() 		return false end
function modifier_phoenix_sun_ray_lua_thinker:IsStunDebuff() 			return false end
function modifier_phoenix_sun_ray_lua_thinker:RemoveOnDeath() 			return true end

function modifier_phoenix_sun_ray_lua_thinker:OnCreated()
	if not IsServer() then
		return
	end
	self:SetStackCount(1)
end

function modifier_phoenix_sun_ray_lua_thinker:OnRefresh()
	if not IsServer() then
		return
	end
	self:IncrementStackCount()
end