-- Created by Sharebophar
--[[
-- 通过改写美杜莎的魔法盾 来学习开关技能（巫医的治疗技能）
]]
--------------------------------------------------------------------------------
witch_doctor_voodoo_restoration_lua = class({})
LinkLuaModifier( "modifier_witch_doctor_voodoo_restoration_lua", "lua_abilities/witch_doctor_voodoo_restoration_lua/modifier_witch_doctor_voodoo_restoration_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_witch_doctor_voodoo_restoration_lua_thinker", "lua_abilities/witch_doctor_voodoo_restoration_lua/modifier_witch_doctor_voodoo_restoration_lua_thinker", LUA_MODIFIER_MOTION_NONE )
--------------------------------------------------------------------------------
-- Ability Start
function witch_doctor_voodoo_restoration_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()

	-- load data
	local value1 = self:GetSpecialValueFor("some_value")

	-- logic

end
--------------------------------------------------------------------------------
-- Toggle
function witch_doctor_voodoo_restoration_lua:OnToggle()
	-- unit identifier
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName( "modifier_witch_doctor_voodoo_restoration_lua" )

    -- 开启技能且没有修改器时，添加治疗修改器；关闭技能时如果有治疗修改器，则移除修改器
	if self:GetToggleState() then
		if not modifier then
			caster:AddNewModifier(
				caster, -- player source
				self, -- ability source
				"modifier_witch_doctor_voodoo_restoration_lua", -- modifier name
				{} -- kv
			)
		end
	else
		if modifier then
			modifier:Destroy()
		end
	end
end
function witch_doctor_voodoo_restoration_lua:ProcsMagicStick()
	return false
end

--------------------------------------------------------------------------------
-- Ability Events
function witch_doctor_voodoo_restoration_lua:OnUpgrade()
	-- refresh values if on
	local modifier = self:GetCaster():FindModifierByName( "modifier_witch_doctor_voodoo_restoration_lua" )
	if modifier then
		modifier:ForceRefresh()
	end
end