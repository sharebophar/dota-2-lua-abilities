
function Sunder( keys )
	
	local caster = keys.caster
	local target = keys.target
    local ability = keys.ability
    
    local minimum_pct = ability:GetLevelSpecialValueFor("hit_point_minimum_pct", (ability:GetLevel() -1))
    local nTargetPct = target:GetHealthPercent()
    if nTargetPct < minimum_pct then
        nTargetPct = minimum_pct
    end

    local nCasterPct = caster:GetHealthPercent()
    if nCasterPct < minimum_pct then
        nCasterPct = minimum_pct
    end

    local nTargetNewHealth = target:GetMaxHealth() * nCasterPct / 100
    local nCasterNewHealth = caster:GetMaxHealth() * nTargetPct / 100

    target:SetHealth(nTargetNewHealth)
    caster:SetHealth(nCasterNewHealth)


    local p_name = "particles/units/heroes/hero_terrorblade/terrorblade_sunder.vpcf"
    if caster.Slots and caster.Slots["back"] and caster.Slots["back"]["itemDef"] == "9750" then
        p_name = "particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8.vpcf"
    end
    local p = ParticleManager:CreateParticle(p_name, PATTACH_POINT_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(p, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", Vector(0, 0, 0), true)
    ParticleManager:SetParticleControlEnt(p, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)

    if caster.prismatic then
        local sHexColor = Wearable.prismatics[caster.prismatic].hex_color
        local vColor = HexColor2RGBVector(sHexColor)
        ParticleManager:SetParticleControl(p, 16, Vector(1, 0, 0))
        ParticleManager:SetParticleControl(p, 15, vColor)
    end

end


	
