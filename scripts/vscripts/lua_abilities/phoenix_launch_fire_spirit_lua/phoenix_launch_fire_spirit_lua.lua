phoenix_launch_fire_spirit_lua = class({})

function phoenix_launch_fire_spirit_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local buff = caster:FindModifierByName("modifier_phoenix_fire_spirits_lua")
    self.fire_count = buff:GetStackCount()
    self.fire_count = self.fire_count - 1
    buff:SetStackCount(self.fire_count)
    -- 播放子弹效果

	if self.fire_count == 0 then
        caster:RemoveModifierByName("modifier_phoenix_fire_spirits_lua")
        caster:SwapAbilities("phoenix_fire_spirits_lua","phoenix_launch_fire_spirit_lua",true,false)
    end
end