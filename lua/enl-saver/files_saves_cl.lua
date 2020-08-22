local saver = ENL.Saver

saver.savePath = saver.dataDir..'/saves.txt'

function saver:GetSaves()
    return NStr:FromJson(file.Read(saver.savePath, 'DATA') or '') or {}
end

function saver:GetSave(name)
    return self:GetSaves()[name]
end

function saver:WriteSaveData(tbl)
    return file.Write(saver.savePath, NStr:ToJson(tbl))
end

function saver:SaveExists(saveName)
    return tobool(self:GetSave(saveName))
end

function saver:RemoveSave(saveName)
    local data = self:GetSaves()
    data[saveName] = nil
    self:WriteSaveData(data)
end

function saver:RenameSave(old,new)
    local data = self:GetSaves()
    data[new] = data[old]
    data[old] = nil
    self:WriteSaveData(data)
end

function saver:SaveEnts(saveName)
    local fl = self:GetSaves()
    if !file.IsDir(saver.dataDir,'DATA') then
        file.CreateDir(saver.dataDir)
    end
    local function Write()
        if table.Count(saver.Ents) <= 0 then return end
        local tbl = {[1]=false}
        for ent,_ in pairs(saver.Ents) do
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
                if !tbl[1] then
                    tbl[1] = data
                end
                if data.wpos.z <= tbl[1].wpos.z then
                    tbl[1] = data
                    rmID = i
                end
            end
        end
        for i,data in pairs(tbl) do
            if i == 1 then
                data.lpos = data.wpos data.lang = data.wang
            else
                data.lpos = tbl[1].ent:WorldToLocal(data.wpos)
                data.lang = tbl[1].ent:WorldToLocalAngles(data.wang)
            end
        end
        table.remove(tbl,rmID)
        fl[saveName] = tbl
        file.Write(saver.savePath,util.TableToJSON(fl))
    end
  
    if fl[saveName] then
        NGUI:AcceptDialogue(l('Rewrite existing save')..' '
        ..saveName..'?', 'Yes', 'No', Write)
    else
        Write()
    end
    saver.Ents = {}
end