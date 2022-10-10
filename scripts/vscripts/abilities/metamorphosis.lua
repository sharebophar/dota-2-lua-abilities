--[[Author: Pizzalol/Noya
	Date: 10.01.2015.
	Swaps the ranged attack, projectile and caster model
]]
function ModelSwapStart( keys )
    local caster = keys.caster
    
	local model = "models/heroes/terrorblade/demon.vmdl"
	local projectile_model = "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf"

	-- Saves the original model and attack capability
	if caster.caster_model == nil then 
		caster.caster_model = caster:GetModelName()
	end
	caster.caster_attack = caster:GetAttackCapability()

	-- Sets the new model and projectile
	caster:SetOriginalModel(model)
	caster:SetRangedProjectileName(projectile_model)

	-- Sets the new attack type
    caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    
    local p_transform = "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform.vpcf"
    local p = ParticleManager:CreateParticle(p_transform, PATTACH_POINT_FOLLOW, caster)
    if caster.prismatic then
        local sHexColor = Wearable.prismatics[caster.prismatic].hex_color
        local vColor = HexColor2RGBVector(sHexColor)
        ParticleManager:SetParticleControl(p, 16, Vector(1, 0, 0))
        ParticleManager:SetParticleControl(p, 15, vColor)
    end
    Wearable:HideWearables(caster)

    local p_metamorphosis = "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf"
    local p2 = ParticleManager:CreateParticle(p_metamorphosis, PATTACH_POINT_FOLLOW, caster)
    if caster.prismatic then
        local sHexColor = Wearable.prismatics[caster.prismatic].hex_color
        local vColor = HexColor2RGBVector(sHexColor)
        ParticleManager:SetParticleControl(p2, 16, Vector(1, 0, 0))
        ParticleManager:SetParticleControl(p2, 15, vColor)
    end

    local p_metamorphosis_head = "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_head.vpcf"
    local p3 = ParticleManager:CreateParticle(p_metamorphosis_head, PATTACH_POINT_FOLLOW, caster)
    if caster.prismatic then
        local sHexColor = Wearable.prismatics[caster.prismatic].hex_color
        local vColor = HexColor2RGBVector(sHexColor)
        ParticleManager:SetParticleControl(p3, 16, Vector(1, 0, 0))
        ParticleManager:SetParticleControl(p3, 15, vColor)
    end
end

--[[Author: Pizzalol/Noya
	Date: 10.01.2015.
	Reverts back to the original model and attack type
]]
function ModelSwapEnd( keys )
	local caster = keys.caster

    if caster:GetModelName() == caster.caster_model then
        return
    end

	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)
    caster:SetAttackCapability(caster.caster_attack)
    
    Wearable:ShowWearables(caster)
end