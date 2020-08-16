net.Receive(ENL.Saver.netstr, function()
    local doempty = net.ReadBool()
    local ent = net.ReadEntity()
    if !doempty then
        if IsValid(ent) then
            ENL.Saver.Ents[ent] = ENL.Saver.Ents[ent] and nil or true
        end
    else
        for ent, _ in pairs(ENL.Saver.Ents) do
            ENL.Saver.Ents[ent] = nil
        end
    end
end)