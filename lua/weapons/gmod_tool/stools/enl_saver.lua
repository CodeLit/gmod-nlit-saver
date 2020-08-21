TOOL.Category = 'Construction'
TOOL.Name = '#tool.enl_saver.name'

local saver = ENL.Saver

if SERVER then

	function TOOL:LeftClick(tr)
	  local ent,ply = tr.Entity,self:GetOwner()
    if !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then
      return false
    end
    net.Start(saver.netstr)
    net.WriteBool(false)
    net.WriteEntity(ent)
    net.Send(ply)
	  return true
	end

	function TOOL:RightClick(tr)
	  return self:LeftClick(tr)
  end
  
  function TOOL:Reload()
    return true
  end

elseif CLIENT then

  saver.LastSpawn = saver.LastSpawn or CurTime()

  function TOOL:BuildCPanel()
    saver:CreateUI(self)
  end
  
  local cantNotify

  function TOOL:Reload()
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

end