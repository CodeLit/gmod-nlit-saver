-- [do not obfuscate]

local saver = ENL.Saver

saver.Ents = saver.Ents or {}
saver.ClientProps = saver.ClientProps or {}
saver.wPosCvar = CreateClientConVar('enl_saver_worldposspawns','0', false)

function saver:GetSpawnDelay()
  local addTime = NCfg:Get('Saver','Delay Between Single Propspawn')
  if NL and NL.CustomNet and NL.CustomNet.GetDelayBetweenSameNetStrings then
    addTime = addTime + NL.CustomNet.GetDelayBetweenSameNetStrings()
  end
  return addTime
end

local updTimer = 'enl-saver-update-cl-props'

function saver:SetClientProps()
  local ply = LocalPlayer()
  if self.previewCvar:GetBool() then
    timer.Create(updTimer, 0, 0, function()
      local tbl = self:GetSelectedSave() or {}
      local firstEnt
      for i, data in pairs(tbl or {}) do
        local existed = self.ClientProps[i]
        local cliProp = existed or ents.CreateClientProp(data.mdl)
        cliProp:SetModel(data.mdl)
        if self.wPosCvar:GetBool() then
          cliProp:SetPos(data.wpos)
          cliProp:SetAngles(data.wang)
        else
          
          if IsValid(firstEnt) then
            cliProp:SetPos(firstEnt:LocalToWorld(data.lpos))
            cliProp:SetAngles(firstEnt:LocalToWorldAngles(data.lang))
          else
            local tr = ply:GetEyeTrace()
            cliProp:SetPos(tr.HitPos)
            local ang = ply:EyeAngles()
            ang:RotateAroundAxis(ply:GetRight(),-90)
            cliProp:SetAngles(Angle(0,ang.y,0))
            -- cliProp:SetPos(cliProp:GetPos()+Vector(0, 0, cliProp:GetModelRadius()))
          end
          firstEnt = firstEnt or cliProp
        end
        if !existed then
          local phys = cliProp:GetPhysicsObject()
          if IsValid(phys) then
            phys:EnableMotion(false)
          end
          cliProp:Spawn()
          self.ClientProps[i] = cliProp
        end
      end
    end)
  else
    if !table.IsEmpty(self.ClientProps) then
      for _, ent in pairs(self.ClientProps) do
        if IsValid(ent) then
          ent:Remove()
        else
          self.ClientProps = {}
        end
      end
      self.ClientProps = {}
      timer.Remove(updTimer)
    end
  end 
end

function saver:SpawnEnts(tbl)
  local coolDownTimeLeft = math.Round((self.LastSpawn +
    NCfg:Get('Saver','Save Cooldown'))-CurTime(),1)

  if coolDownTimeLeft >= 0 then
    LocalPlayer():Notify(l('Saver cannot work too often')..'.'..l('Time left')
      ..': '..coolDownTimeLeft..' '..l('sec.'))
    return
  end
  if self.InProgress then return end
  self.InProgress = true

  timer.Create('NL Duplicator Progress Timer',(self:GetSpawnDelay()*table.Count(tbl)),1,function()
    saver.LastSpawn = CurTime()
    saver.InProgress = nil
    saver.Abort = nil
  end)

  local useWPos = self.wPosCvar:GetBool()
  for i,data in pairs(tbl) do
    timer.Simple(self:GetSpawnDelay()*(i-1),function()
      if saver.Abort then return end
      net.Start(saver.netstr)
      if !useWPos then data.wpos = nil end
      if i == 1 then data.firstEnt = true end
      data.useWPos = (useWPos or nil)
      net.WriteTable(data)
      net.SendToServer()
    end)
  end
  RunConsoleCommand(self.previewCvar:GetName(),0)
end
