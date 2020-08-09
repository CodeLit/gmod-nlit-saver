ENL = ENL or {}
ENL.Saver = ENL.Saver or {}
ENL.Saver.netstr = 'ENL Saver'
ENL.Saver.freezeCvarName = 'enl_saver_freeze'


function ENL.Saver:CanProceedEnt(ply,ent)
  if !IsValid(ply) or !IsValid(ent) then return end
  local function Note(text) ply:PrintMessage(HUD_PRINTCENTER,text) end
  if !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then
    Note('Предмет должен быть пропом')
    return
  end
  if ply:GetPos():Distance(ent:GetPos()) > NCfg:Get('Saver','Max. Items Spawn Distance') then
    Note('Слишком большое расстояние до предмета') return false end
  local tr = util.TraceLine({start=ply:EyePos(),endpos=ent:WorldSpaceCenter(),
    filter = function(e) if e.SID != ply.SID then return true end end
  })
  -- if tr.Hit then Note('Предмет вне поля видимости') return false end
  for _,ent in pairs(ents.FindInSphere(ent:GetPos(),ent:BoundingRadius() or 50)) do
    if ent:IsPlayer() then Note('Игрок блокирует спавн предмета') return false end
  end
  return true
end