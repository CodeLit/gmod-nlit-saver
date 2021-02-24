TOOL.Category = 'Construction'
TOOL.Name = '#tool.'..CWSaver.tool..'.name'

local l = CW:Lib('translator')

if CLIENT then

  CWSaver.LastSpawn = CWSaver.LastSpawn or CurTime()

  function TOOL:BuildCPanel()
    CWSaver:CreateUI(self)
  end

  local function SelectEnt(ent,bSelect)
    if !IsValid(ent) or !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then
      return true
    else
      CWSaver.Ents[ent] = bSelect
    end
    return true
  end
  
  function TOOL:LeftClick(tr)
	  return SelectEnt(tr.Entity,true)
	end

	function TOOL:RightClick(tr)
	  return SelectEnt(tr.Entity,false)
  end

  local cantNotify

  function TOOL:Reload(tr)
    CWSaver.Ents = {}
    if !cantNotify then
      LocalPlayer():Notify(l('Selection was cleared')..'.',2)
      cantNotify = true
      timer.Simple(0.01, function()
        cantNotify = nil
      end)
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