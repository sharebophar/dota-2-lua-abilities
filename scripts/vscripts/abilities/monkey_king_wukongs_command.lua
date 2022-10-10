function SpellStart( keys )
    print("SpellStart")
    for k,v in pairs(keys) do
        print(k,v)
    end
end

function AbilityPhaseStart( keys )
    print("AbilityPhaseStart")
    for k,v in pairs(keys) do
        print(k,v)
    end
end