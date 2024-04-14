nlitSaver = nlitSaver or {}
nlitSaver.tool = 'nlit_saver'
nlitSaver.netstr = 'nlit Saver'
nlitSaver.freezeCvarName = nlitSaver.tool .. '_freeze'
nlitSaver.dataDir = nlitSaver.tool
nlitSaver.Debug = true
local Ents = nlitLib:Load('ents')
local l = nlitLib:Load('lang')
function nlitSaver:debug(txt) -- print
  if self.Debug then print('[Nlit\'s Saver][DEBUG] ' .. txt) end
end

function nlitSaver:IsPlyHolding(ply)
  local act = ply:GetActiveWeapon()
  local tool = ply:GetTool()
  return IsValid(act) and act:GetClass() == 'gmod_tool' and tool and tool.Mode == self.tool
end

function nlitSaver:CanProceedEnt(ply, ent, bDontNotify)
  if not IsValid(ply) or not IsValid(ent) then return end
  local function Notify(pl, message)
    if not bDontNotify then pl:Notify(message) end
  end

  if not table.HasValue(nlitCfg:Get('Saver', 'Classes To Save'), ent:GetClass()) and ent:GetClass() ~= 'class C_PhysPropClientside' then
    Notify(ply, l('The item must be a prop', ply:GetLang()) .. '!')
    return
  end

  if ply:GetPos():Distance(ent:GetPos()) > nlitCfg:Get('Saver', 'Max. Items Spawn Distance') then
    Notify(ply, l('There is too far for the object', ply:GetLang()) .. '!')
    return false
  end

  local function filter(e)
    if e.SID ~= ply.SID then return true end
  end

  local tr = util.TraceLine({
    start = ply:EyePos(),
    endpos = ent:WorldSpaceCenter(),
    filter = filter
  })

  if tr.Hit then
    Notify(ply, l('The item is not in your view area', ply:GetLang()) .. '!')
    return false
  end

  if Ents:IsStuckingPly(ent) then
    Notify(ply, l('Player is blocking item spawn', ply:GetLang()) .. '!')
    return false
  end
  return true
end

nlitSaver:debug('LIB LOADED!')