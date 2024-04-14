nlitSaver.savePath = nlitSaver.dataDir .. '/saves.txt'
local Str = nlitString
function nlitSaver:GetSaves()
    return Str:FromJson(file.Read(self.savePath, 'DATA') or '') or {}
end

function nlitSaver:GetSave(name)
    local saves = self:GetSaves()
    return saves[name] or nil
end

function nlitSaver:GetSelectedSave()
    local sel = self.savesList:GetSelected()
    if not sel or not sel[1] then return end
    return self:GetSave(sel[1]:GetColumnText(1))
end

function nlitSaver:WriteSaveData(tbl)
    return file.Write(self.savePath, Str:ToJson(tbl))
end

function nlitSaver:SaveExists(saveName)
    return tobool(self:GetSave(saveName))
end

function nlitSaver:RemoveSave(saveName)
    local data = self:GetSaves()
    data[saveName] = nil
    self:WriteSaveData(data)
end

function nlitSaver:RenameSave(old, new)
    local data = self:GetSaves()
    data[new] = data[old]
    data[old] = nil
    self:WriteSaveData(data)
end

function nlitSaver:SaveEnts(saveName)
    local fl = self:GetSaves()
    if not file.IsDir(self.dataDir, 'DATA') then file.CreateDir(self.dataDir) end
    local function Write()
        if table.Count(self.Ents) <= 0 then return end
        local tbl = {
            [1] = false
        }

        for ent, _ in pairs(self.Ents) do
            local instbl = {
                mdl = ent:GetModel()
            }

            instbl.ent = ent
            instbl.class = ent:GetClass()
            instbl.wpos = ent:GetPos()
            instbl.wang = ent:GetAngles()
            instbl.mat = ent:GetMaterial()
            -- Даём трасер в пол, и записываем высоту
            local tr = util.QuickTrace(ent:GetPos(), ent:WorldSpaceCenter() - Vector(0, 0, 3000), ent)
            instbl.startH = tr.StartPos.z - tr.HitPos.z
            local clr = ent:GetColor()
            if clr ~= Color(255, 255, 255) then instbl.col = clr end
            table.insert(tbl, instbl)
        end

        local rmID
        for i, data in pairs(tbl) do
            -- записать первый элемент как самый низкий по Z
            if i ~= 1 then
                if not tbl[1] then tbl[1] = data end
                if data.wpos.z <= tbl[1].wpos.z then
                    tbl[1] = data
                    rmID = i
                end
            end
        end

        for i, data in pairs(tbl) do
            if i == 1 then
                data.lpos = data.wpos
                data.lang = data.wang
            else
                data.lpos = tbl[1].ent:WorldToLocal(data.wpos)
                data.lang = tbl[1].ent:WorldToLocalAngles(data.wang)
            end
        end

        table.remove(tbl, rmID)
        fl[saveName] = tbl
        file.Write(self.savePath, util.TableToJSON(fl))
    end

    if fl[saveName] then
        NGUI:AcceptDialogue(l('Rewrite existing save') .. ' ' .. saveName .. '?', 'Yes', 'No', Write)
    else
        Write()
    end

    self.Ents = {}
end

nlitSaver:debug('FILES SAVES LOADED!')