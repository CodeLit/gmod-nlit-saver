ENL = ENL or {}
ENL.Saver = ENL.Saver or {}
ENL.Saver.netstr = 'ENL Saver'
ENL.Saver.freezeCvarName = 'enl_saver_freeze'
--ENL.Saver.SpawnedProps = ENL.Saver.SpawnedProps or {}
ENL.Saver.savePath = 'enl_saver/saves'

function ENL.Saver:CanProceedEnt(ply,ent)
  if !IsValid(ply) or !IsValid(ent) then return end
  if !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then
    ply:Notify(l('The item must be a prop')..'!')
    return
  end
  if ply:GetPos():Distance(ent:GetPos()) > NCfg:Get('Saver','Max. Items Spawn Distance') then
    ply:Notify(l('The item must be a prop')..'!')
    ply:Notify(l('There is too far for the object')..'!') return false end
  local tr = util.TraceLine({start=ply:EyePos(),endpos=ent:WorldSpaceCenter(),
    filter = function(e) if e.SID != ply.SID then return true end end
  })
  -- if tr.Hit then Note('Предмет вне поля видимости') return false end
  for _,ent in pairs(ents.FindInSphere(ent:GetPos(),ent:BoundingRadius() or 50)) do
    if ent:IsPlayer() then ply:Notify(l('Player is blocking item spawn')..'!') return false end
  end
  
  return true
end