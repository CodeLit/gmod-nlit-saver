local l = nlitLib:Load('lang')
nlitSaver.Ents = nlitSaver.Ents or {}
nlitSaver.ClientProps = nlitSaver.ClientProps or {}
nlitSaver.wPosCvar = CreateClientConVar(nlitSaver.tool .. '_worldposspawns', '0', false)
function nlitSaver:GetSpawnDelay()
  local addTime = nlitCfg:Get('Saver', 'Delay Between Single Propspawn')
  if NL and NL.CustomNet and NL.CustomNet.GetDelayBetweenSameNetStrings then addTime = addTime + NL.CustomNet.GetDelayBetweenSameNetStrings() end
  return addTime
end

local updTimer = 'nlitSaver-update-cl-props'
function nlitSaver:SetClientProps()
  local ply = LocalPlayer()
  self:ClearClientProps()
  if self.previewCvar:GetBool() then
    timer.Create(updTimer, 0.033, 0, function()
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
            cliProp:SetPos(tr.HitPos + Vector(0, 0, data.startH or 0))
            local ang = ply:EyeAngles()
            ang:RotateAroundAxis(ply:GetRight(), -90)
            ang.p = data.wang.p
            -- ang.y = data.wang.y
            ang.r = data.wang.r
            cliProp:SetAngles(ang)
          end

          firstEnt = firstEnt or cliProp
        end

        if not existed then
          local phys = cliProp:GetPhysicsObject()
          if IsValid(phys) then phys:EnableMotion(false) end
          cliProp:Spawn()
          self.ClientProps[i] = cliProp
        end

        cliProp:SetNoDraw(not nlitSaver:CanProceedEnt(ply, cliProp, true) or not nlitSaver:IsPlyHolding(LocalPlayer()))
      end
    end)
  else
    timer.Remove(updTimer)
  end
end

function nlitSaver:ClearClientProps()
  if not table.IsEmpty(self.ClientProps) then
    for i, ent in pairs(self.ClientProps) do
      if IsValid(ent) then ent:Remove() end
      self.ClientProps[i] = nil
    end
  end
end

function nlitSaver:SpawnEnts(tbl)
  local coolDownTimeLeft = math.Round((self.LastSpawn + nlitCfg:Get('Saver', 'Save Cooldown')) - CurTime(), 1)
  if coolDownTimeLeft >= 0 then
    LocalPlayer():Notify(l('Saver cannot work too often') .. '.' .. l('Time left') .. ': ' .. coolDownTimeLeft .. ' ' .. l('sec') .. '.')
    return
  end

  if self.InProgress then return end
  self.InProgress = true
  timer.Create('NL Duplicator Progress Timer', self:GetSpawnDelay() * table.Count(tbl), 1, function()
    nlitSaver.LastSpawn = CurTime()
    nlitSaver.InProgress = nil
    nlitSaver.Abort = nil
  end)

  local useWPos = self.wPosCvar:GetBool()
  for i, data in pairs(tbl) do
    timer.Simple(self:GetSpawnDelay() * (i - 1), function()
      if nlitSaver.Abort then return end
      net.Start(nlitSaver.netstr)
      if not useWPos then data.wpos = nil end
      if i == 1 then data.firstEnt = true end
      data.useWPos = useWPos or nil
      net.WriteTable(data)
      net.SendToServer()
    end)
  end

  RunConsoleCommand(self.previewCvar:GetName(), 0)
end

nlitSaver:debug('LIB CL LOADED!')