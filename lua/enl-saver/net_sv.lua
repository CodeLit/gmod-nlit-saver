local firstEnts = {}

net.Receive(ENL.Saver.netstr,function(_,ply)

    local data = net.ReadTable()
    if !(isvector(data.wpos) or isvector(data.lpos))
    
    or !isangle(data.wang) or !isstring(data.mdl) then return end
    if !hook.Run('PlayerSpawnProp',ply,data.mdl) then return end
    local prop = ents.Create(data.class)
    if data.useWPos then
        prop:SetPos(data.wpos)
        prop:SetAngles(data.wang)
    else
        local ang = ply:EyeAngles()
        ang:RotateAroundAxis(ply:GetRight(),-90)
        prop:SetAngles(Angle(0,ang.y,0))
        if data.firstEnt then
            local trace = ply:GetEyeTrace()
            prop:SetPos(trace.HitPos)
        else
            local fent = firstEnts[ply:SteamID()]
            if !IsValid(fent) then return end
            prop:SetPos(fent:LocalToWorld(data.lpos))
            prop:SetAngles(fent:LocalToWorldAngles(data.lang))
        end
    end

    prop:SetModel(data.mdl)
    
    if !ENL.Saver:CanProceedEnt(ply,prop) then prop:Remove() return end

    if prop.CPPISetOwner then
        prop:CPPISetOwner(ply)
    end

    prop.SID = ply.SID
    prop:Spawn()
    
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

    local phys = prop:GetPhysicsObject()
    if phys then
        if data.firstEnt and !data.useWPos then
        local mins,maxs = phys:GetAABB()
        prop:SetPos(prop:GetPos()+Vector(0,0,maxs.z+10))
        end
        phys:EnableMotion(!tobool(ply:GetInfo(ENL.Saver.freezeCvarName)))
    end

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
        prop:DropToFloor()
    end

end)