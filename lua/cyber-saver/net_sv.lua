local firstEnts = {}

net.Receive(CW.Saver.netstr,function(_,ply)

    local data = net.ReadTable()
    if !(isvector(data.wpos) or isvector(data.lpos))

    or !isangle(data.wang) or !isstring(data.mdl) then return end
    if !hook.Run('PlayerSpawnProp',ply,data.mdl) then return end

    local prop = ents.Create(data.class)

    -- Первое размещение
    if data.useWPos then
        prop:SetPos(data.wpos)
        prop:SetAngles(data.wang)
    else
        local ang = ply:EyeAngles()
        ang:RotateAroundAxis(ply:GetRight(),-90)
        prop:SetAngles(Angle(0,ang.y,0))
        if data.firstEnt then
            local trace = ply:GetEyeTrace()
            local spawnPos = trace.HitPos
            spawnPos.z = spawnPos.z + data.startH/2+5
            prop:SetPos(spawnPos)
            local a = prop:GetAngles()
            a.r = data.wang.r
            prop:SetAngles(a)
        else
            local fent = firstEnts[ply:SteamID()]
            if !IsValid(fent) then return end
            prop:SetPos(fent:LocalToWorld(data.lpos))
            prop:SetAngles(fent:LocalToWorldAngles(data.lang))
        end
    end

    prop:SetModel(data.mdl)
    prop:Spawn()

    -- Фризинг
    local phys = prop:GetPhysicsObject()
    if phys then
        phys:EnableMotion(!tobool(ply:GetInfo(CW.Saver.freezeCvarName)))
    end

    if !CW.Saver:CanProceedEnt(ply,prop) then prop:Remove() return end
    
    // timer.Simple(0, function ()
    //     prop:DropToFloor() // Кидаем на пол предметы с плохой физ. моделью
    // end)
    

    if prop.CPPISetOwner then
        prop:CPPISetOwner(ply)
    end

    prop.SID = ply.SID

    if NCfg:Get('Saver','Create Indestructible Items') then
        prop:SetVar('Unbreakable',true)
        prop:Fire('SetDamageFilter','FilterDamage',0)
    end

    gamemode.Call('PlayerSpawnedProp',ply,data.mdl,prop)
    cleanup.Add(ply,'props',prop)
    undo.Create('prop')
    undo.AddEntity(prop)
    undo.SetPlayer(ply)
    undo.Finish()

    if APA and APA.InitGhost then
        timer.Simple(1,function()
            APA.InitGhost(prop,true,false,false,true)
            -- ent,ghostoff,nofreeze,collision,forcefreeze
        end)
    end

    if data.mat and data.mat != prop:GetMaterial() then
        prop:SetMaterial(data.mat)
    end

    local color = (data.col and Color(data.col.r,data.col.g,data.col.b,data.col.a))

    if IsColor(color) then prop:SetColor(color) end

    if data.firstEnt then
        firstEnts[ply:SteamID()] = prop
    end

end)