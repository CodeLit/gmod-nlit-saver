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
    for i,data in pairs(tbl) do // записать первый элемент как самый низкий по Z
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
    NGUI:AcceptDialogue('Перезаписать уже имеющийся файл '..filename..'?', 'Yes', 'No', Write)
  else
    Write()
  end
  ENL.Saver.Ents = {}
end

hook.Add('HUDPaint','ENL Dulpicator Progress',function()
  if !ENL.Saver.InProgress or ENL.Saver.Abort then return end
  local text = l('Saver is creating objects')..'...'
    ..math.Round(timer.TimeLeft('NL Duplicator Progress Timer'),1)
  local txtdata = {text=text,font='DermaLarge',pos={ScrW()-450,ScrH()/15},color=Color(255,255,255)}
  draw.Text(txtdata)
  draw.TextShadow(txtdata,2,200)
  txtdata.text = l('Press R button to reject creation')..'.'
  txtdata.pos = {ScrW()-510,ScrH()/10}
  draw.Text(txtdata)
  draw.TextShadow(txtdata,2,200)
  if ENL.Saver.InProgress and LocalPlayer():KeyPressed(IN_RELOAD) then
    ENL.Saver.Abort = true
  end
end)

hook.Add('PreDrawHalos', 'ENL Duplicator Draw', function()
  if !table.IsEmpty(ENL.Saver.Ents) then
    local wep, tool = LocalPlayer():GetActiveWeapon(), LocalPlayer():GetTool()
    if !IsValid(wep) or wep:GetClass() != 'gmod_tool'
      or tool.Mode != 'enl_saver' then return end
  
    local haloEnts = {}
    for ent, bool in pairs(ENL.Saver.Ents) do
      if bool and IsValid(ent) then table.insert(haloEnts, ent)
      else ENL.Saver.Ents[ent] = nil end
    end
    halo.Add(haloEnts, Color( 51, 255, 51 ), 1, 1, 15, true, true)
  end

  if !table.IsEmpty(ENL.Saver.ClientProps) then
    local haloEnts = {}
    for _, ent in pairs(ENL.Saver.ClientProps) do
      table.insert(haloEnts, ent)
    end
    halo.Add(haloEnts, NC:White(), 1, 1, 15, true, true)
  end
end)