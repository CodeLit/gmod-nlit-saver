local firstEnts = {}
net.Receive(CWSaver.netstr, function(_, ply)
    local data = net.ReadTable()
    if not (isvector(data.wpos) or isvector(data.lpos)) or not isangle(data.wang) or not isstring(data.mdl) then return end
    if not hook.Run('PlayerSpawnProp', ply, data.mdl) then return end
    local prop = ents.Create(data.class)
    -- Первое размещение
    if data.useWPos then
        prop:SetPos(data.wpos)
        prop:SetAngles(data.wang)
    else
        local ang = ply:EyeAngles()
        ang:RotateAroundAxis(ply:GetRight(), -90)
        if data.firstEnt then
            local trace = ply:GetEyeTrace()
            local spawnPos = trace.HitPos
            spawnPos.z = spawnPos.z + data.startH
            prop:SetPos(spawnPos)
            local a = prop:GetAngles()
            a.r = data.wang.r
            a.y = ang.y
            prop:SetAngles(a)
            -- timer.Simple(0, function ()
            --     if !IsValid(prop) then return end
            --     prop:DropToFloor() // Кидаем на пол предметы с плохой физ. моделью
            -- end)
        else
            local fent = firstEnts[ply:SteamID()]
            if not IsValid(fent) then return end
            prop:SetPos(fent:LocalToWorld(data.lpos))
            prop:SetAngles(fent:LocalToWorldAngles(data.lang))
        end
    end

    prop:SetModel(data.mdl)
    prop:Spawn()
    -- Фризинг
    local phys = prop:GetPhysicsObject()
    if phys then phys:EnableMotion(not tobool(ply:GetInfo(CWSaver.freezeCvarName))) end
    if not CWSaver:CanProceedEnt(ply, prop) then
        prop:Remove()
        return
    end

    if prop.CPPISetOwner then prop:CPPISetOwner(ply) end
    prop.SID = ply.SID
    if nlitCfg:Get('Saver', 'Create Indestructible Items') then
        prop:SetVar('Unbreakable', true)
        prop:Fire('SetDamageFilter', 'FilterDamage', 0)
    end

    gamemode.Call('PlayerSpawnedProp', ply, data.mdl, prop)
    cleanup.Add(ply, 'props', prop)
    undo.Create('prop')
    undo.AddEntity(prop)
    undo.SetPlayer(ply)
    undo.Finish()
    if APA and APA.InitGhost then
        timer.Simple(1, function()
            APA.InitGhost(prop, true, false, false, true)
            -- ent,ghostoff,nofreeze,collision,forcefreeze
        end)
    end

    if data.mat and data.mat ~= prop:GetMaterial() then prop:SetMaterial(data.mat) end
    local color = data.col and Color(data.col.r, data.col.g, data.col.b, data.col.a)
    if IsColor(color) then prop:SetColor(color) end
    if data.firstEnt then firstEnts[ply:SteamID()] = prop end
end)

CWSaver:debug('NET LOADED!')