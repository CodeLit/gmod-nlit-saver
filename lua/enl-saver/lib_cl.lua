-- [do not obfuscate]

local saver = ENL.Saver

saver.Ents = saver.Ents or {}
saver.ClientProps = saver.ClientProps or {}
saver.wPosCvar = CreateClientConVar('enl_saver_worldposspawns','0')

function saver:GetSpawnDelay()
  local addTime = NCfg:Get('Saver','Delay Between Single Propspawn')
  if NL and NL.CustomNet and NL.CustomNet.GetDelayBetweenSameNetStrings then
    addTime = addTime + NL.CustomNet.GetDelayBetweenSameNetStrings()
  end
  return addTime
end

function saver:ClientProp(bDelete, tbl)
  if !bDelete then
      for i, data in pairs(tbl) do
        local client = ents.CreateClientProp(data.mdl)
        client:SetPos(data.wpos)
        client:SetAngles(data.wang)
        client:GetPhysicsObject():EnableMotion(false)
        client:Spawn()

        table.insert(saver.ClientProps, client)
      end
  else
      if !table.IsEmpty(saver.ClientProps) then
        for _, ent in pairs(saver.ClientProps) do
          if IsValid(ent) then
            ent:Remove()
          else
            saver.ClientProps = {}
          end
        end
        saver.ClientProps = {}
      end
  end 
end

function saver:SpawnEnts(tbl)
  local coolDownTimeLeft = math.Round((saver.LastSpawn +
    NCfg:Get('Saver','Save Cooldown'))-CurTime(),1)
  if coolDownTimeLeft >= 0 then
    LocalPlayer():Notify(l('Saver cannot work too often')..'.'..l('Time left')
      ..': '..coolDownTimeLeft..' '..l('sec.'))
    return
  end
  if saver.InProgress then return end
  saver.InProgress = true
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
  saver:ClientProp(true)
end