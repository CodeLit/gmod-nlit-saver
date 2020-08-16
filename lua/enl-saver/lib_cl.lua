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