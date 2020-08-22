-- [do not obfuscate]

ENL.Saver.Ents = ENL.Saver.Ents or {}
ENL.Saver.ClientProps = ENL.Saver.ClientProps or {}
ENL.Saver.wPosCvar = CreateClientConVar('enl_saver_worldposspawns','0')

function ENL.Saver:SaveEnts(filename)
  if !file.IsDir(self.savePath,'DATA') then file.CreateDir(self.savePath) end
  local function Write()
    if table.Count(ENL.Saver.Ents) <= 0 then return end
    local tbl = {[1]=false}
    for ent,_ in pairs(ENL.Saver.Ents) do
      local instbl = {mdl = ent:GetModel()}
      instbl.ent = ent
      instbl.class = ent:GetClass()
      instbl.wpos = ent:GetPos()
      instbl.wang = ent:GetAngles()
      instbl.mat = ent:GetMaterial()
      local clr = ent:GetColor()
      if clr != Color(255,255,255) then instbl.col = clr end
      table.insert(tbl,instbl)
    end
    local rmID
    for i,data in pairs(tbl) do -- записать первый элемент как самый низкий по Z
      if i != 1 then
        if !tbl[1] then tbl[1] = data end
        if data.wpos.z <= tbl[1].wpos.z then
          tbl[1] = data
          rmID = i
        end
      end
    end
    for i,data in pairs(tbl) do
      if i == 1 then data.lpos = data.wpos data.lang = data.wang
      else
        data.lpos = tbl[1].ent:WorldToLocal(data.wpos)
        data.lang = tbl[1].ent:WorldToLocalAngles(data.wang)
      end
    end
    table.remove(tbl,rmID)
    file.Write(self.savePath..'/'..filename..'.txt',util.TableToJSON(tbl))
  end
  if file.Exists(self.savePath..'/'..filename..'.txt','DATA') then
    NGUI:AcceptDialogue(l('Rewrite existing file')..' '
      ..filename..'?', 'Yes', 'No', Write)
  else
    Write()
  end
  ENL.Saver.Ents = {}
end

function ENL.Saver:GetSpawnDelay()
  local addTime = NCfg:Get('Saver','Delay Between Single Propspawn')
  if NL and NL.CustomNet and NL.CustomNet.GetDelayBetweenSameNetStrings then
    addTime = addTime + NL.CustomNet.GetDelayBetweenSameNetStrings()
  end
  return addTime
end

function ENL.Saver:ClientProp(bDelete, tbl)
  if !bDelete then
      for i, data in pairs(tbl) do
        local client = ents.CreateClientProp(data.mdl)
        client:SetPos(data.wpos)
        client:SetAngles(data.wang)
        client:GetPhysicsObject():EnableMotion(false)
        client:Spawn()

        table.insert(ENL.Saver.ClientProps, client)
      end
  else
      if !table.IsEmpty(ENL.Saver.ClientProps) then
        for _, ent in pairs(ENL.Saver.ClientProps) do
          if IsValid(ent) then
            ent:Remove()
          else
            ENL.Saver.ClientProps = {}
          end
        end
        ENL.Saver.ClientProps = {}
      end
  end 
end

function ENL.Saver:SpawnEnts(tbl)
  local coolDownTimeLeft = math.Round((ENL.Saver.LastSpawn + NCfg:Get('Saver','Save Cooldown'))-CurTime(),1)
  if coolDownTimeLeft >= 0 then
    LocalPlayer():Notify(l('Saver cannot work too often')..'.'..l('Time left')
      ..': '..coolDownTimeLeft..' '..l('sec.'))
    return
  end
  if ENL.Saver.InProgress then return end
  ENL.Saver.InProgress = true
  timer.Create('NL Duplicator Progress Timer',(self:GetSpawnDelay()*table.Count(tbl)),1,function()
    ENL.Saver.LastSpawn = CurTime()
    ENL.Saver.InProgress = nil
    ENL.Saver.Abort = nil
  end)
  local useWPos = self.wPosCvar:GetBool()
  for i,data in pairs(tbl) do
    timer.Simple(self:GetSpawnDelay()*(i-1),function()
      if ENL.Saver.Abort then return end
      net.Start(ENL.Saver.netstr)
      if !useWPos then data.wpos = nil end
      if i == 1 then data.firstEnt = true end
      data.useWPos = (useWPos or nil)
      net.WriteTable(data)
      net.SendToServer()
    end)
  end
  ENL.Saver:ClientProp(true)
end