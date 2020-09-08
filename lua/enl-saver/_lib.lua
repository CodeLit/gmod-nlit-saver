-- [do not obfuscate]

ENL = ENL or {}
ENL.Saver = ENL.Saver or {}
ENL.Saver.netstr = 'ENL Saver'
ENL.Saver.freezeCvarName = 'enl_saver_freeze'
ENL.Saver.dataDir = 'enl_saver'

function ENL.Saver:CanProceedEnt(ply,ent)
  if !IsValid(ply) or !IsValid(ent) then return end
  if !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then
    ply:Notify(l('The item must be a prop',ply:GetLang())..'!')
    return
  end
  if ply:GetPos():Distance(ent:GetPos()) > NCfg:Get('Saver','Max. Items Spawn Distance') then
    ply:Notify(l('There is too far for the object',ply:GetLang())..'!')
    return false
  end
  local tr = util.TraceLine({start=ply:EyePos(),endpos=ent:WorldSpaceCenter(),
    filter = function(e) if e.SID != ply.SID then return true end end
  })
  -- if tr.Hit then Note('Предмет вне поля видимости') return false end
  if NEnts:IsStuckingPly(ent) then
    ply:Notify(l('Player is blocking item spawn',ply:GetLang())..'!')
    return false
  end
  
  return true
end