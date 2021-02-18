TOOL.Category = 'Construction'
TOOL.Name = '#tool.'..CW.Saver.tool..'.name'

local l = CW:Lib('translator')

if CLIENT then

  local saver = CW.Saver

  saver.LastSpawn = saver.LastSpawn or CurTime()

  function TOOL:BuildCPanel()
    saver:CreateUI(self)
  end

  local function SelectEnt(ent,bSelect)
    if !IsValid(ent) or !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then
      return true
    else
      saver.Ents[ent] = bSelect
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
    saver.Ents = {}
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