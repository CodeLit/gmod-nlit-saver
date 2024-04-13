TOOL.Category = 'Construction'
TOOL.Name = '#tool.' .. nlitSaver.tool .. '.name'
local l = nlitLang.l
if CLIENT then
  nlitSaver.LastSpawn = nlitSaver.LastSpawn or CurTime()
  function TOOL:BuildCPanel()
    nlitSaver:CreateUI(self)
  end

  local function SelectEnt(ent, bSelect)
    if not IsValid(ent) or not table.HasValue(nlitCfg:Get('Saver', 'Classes To Save'), ent:GetClass()) then
      return true
    else
      nlitSaver.Ents[ent] = bSelect
    end
    return true
  end

  function TOOL:LeftClick(tr)
    return SelectEnt(tr.Entity, true)
  end

  function TOOL:RightClick(tr)
    return SelectEnt(tr.Entity, false)
  end

  local cantNotify
  function TOOL:Reload(tr)
    nlitSaver.Ents = {}
    if not cantNotify then
      LocalPlayer():Notify(l('Selection was cleared') .. '.', 2)
      cantNotify = true
      timer.Simple(0.01, function() cantNotify = nil end)
    end
    return true
  end
elseif SERVER then
  function TOOL:LeftClick(tr)
    return true
  end

  function TOOL:RightClick(tr)
    return self:LeftClick(tr)
  end

  function TOOL:Reload(tr)
    return self:LeftClick(tr)
  end
end