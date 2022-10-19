phoenix_icarus_dive_stop_lua = class({})

function phoenix_icarus_dive_stop_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_phoenix_icarus_dive_lua")

	caster:SwapAbilities("phoenix_icarus_dive_lua","phoenix_icarus_dive_stop_lua",true,false)
end