CWSaver = CWSaver or {}
CWSaver.tool = 'cyber_saver'
CWSaver.netstr = 'Cyber Saver'
CWSaver.freezeCvarName = CWSaver.tool..'_freeze'
CWSaver.dataDir = CWSaver.tool
CWSaver.Debug = true

local Ents = CW:Lib('ents')
local l = CW:Lib('translator')

function CWSaver:debug(txt) -- print
  if self.Debug then
    cwp(txt)
  end
end

function CWSaver:IsPlyHolding(ply)
  local act = ply:GetActiveWeapon()
  local tool = ply:GetTool()
  return IsValid(act) and act:GetClass() == 'gmod_tool' and tool
    and tool.Mode == self.tool
end

function CWSaver:CanProceedEnt(ply,ent,bDontNotify)
  if !IsValid(ply) or !IsValid(ent) then return end
  local function Notify(pl,message)
    if !bDontNotify then
      pl:Notify(message)
    end
  end

  if !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass())
  and ent:GetClass() != 'class C_PhysPropClientside'
  then
    Notify(ply,l('The item must be a prop',ply:GetLang())..'!')
    return
  end

  if ply:GetPos():Distance(ent:GetPos()) > NCfg:Get('Saver','Max. Items Spawn Distance') then
    Notify(ply,l('There is too far for the object',ply:GetLang())..'!')
    return false
  end

  local function filter(e)
    if e.SID != ply.SID then return true end
  end

  local tr = util.TraceLine({
    start=ply:EyePos(),
    endpos=ent:WorldSpaceCenter(),
    filter = filter
  })

  if tr.Hit then
    Notify(ply,l('The item is not in your view area',ply:GetLang())..'!')
    return false
  end

  if Ents:IsStuckingPly(ent) then
    Notify(ply,l('Player is blocking item spawn',ply:GetLang())..'!')
    return false
  end
  
  return true
end

CWSaver:debug('LIB LOADED!')