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

  local freezeCvar = CreateClientConVar(saver.freezeCvarName,'0',true,true)

  language.Add('Tool.enl_saver.name', l('Saver'))
  language.Add('Tool.enl_saver.desc', l('Saves groups of items'))
  language.Add('Tool.enl_saver.0', l('Click on any of items to add / remove it from the bunch. Press [R] to unselect all')..'.')

  saver.LastSpawn = saver.LastSpawn or CurTime()

  function TOOL:BuildCPanel()

    local function AddButton(btn)
      local pnl = self:Add('DPanel')
      pnl:SetTall(30)
      pnl:Dock(TOP)
      pnl:SetText('')
      pnl:DockMargin(20,10,20,0)
      
      btn:SetParent(pnl)
      btn:Dock(FILL)
    end

    self:AddControl('Header', {Text = '#Tool.enl_saver.name', Description = '#Tool.enl_saver.desc'})

		local pnl = self:Add('DPanel')
		pnl:SetTall(30)
		pnl:Dock(TOP)
		pnl:DockMargin(20,10,20,0)

		local edit = vgui.Create('DTextEntry',pnl)
		edit:Dock(FILL)
		edit:SetText('Save 1')
		edit:SelectAllOnFocus()
    function edit:Upd()
      local txt = edit:GetText()
      local exp = string.Explode(' ',txt)
      if string.find(txt,'Save ') == 1 and exp[2] then
        local num = tonumber(exp[2])
        if isnumber(num) then
          while file.Exists(saver.savePath..'/'..'Save '..num..'.txt','DATA') do num = num + 1 end
          edit:SetText('Save '..num)
        end
      end
    end

    edit:Upd()

    AddButton(NGUI:AcceptButton('Save items', function()
      saver:SaveEnts(edit:GetText())
			self.SavesList:Upd()
      edit:Upd()
    end))

    self:AddControl('CheckBox', {
      Label = l('Place with saving world positions'), Command = saver.wPosCvar:GetName()
    })
    self:AddControl('CheckBox', {
      Label = l('Freeze Items On Spawn'), Command = freezeCvar:GetName()
    })

    local list = vgui.Create('DListView', self)
    list:SetTall(ScrH() / 3)
    list:Dock(TOP)
    list:DockMargin(0, 10, 0, 0)
    list:SetMultiSelect(false)
    list:AddColumn(l('Savings'))

		function list:Upd()
			list:Clear()
      local files = file.Find(saver.savePath..'/*.txt','DATA')
      for _,f in pairs(files) do
        f = string.StripExtension(f)
        list:AddLine(f)
      end
		end
		list:Upd()
		self.SavesList = list

    AddButton(NGUI:Button('Show/Hide structure', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(saver.savePath..'/'..filename..'.txt','DATA') then
        local tbl = util.JSONToTable(file.Read(saver.savePath..'/'..filename..'.txt'))
        if !istable(tbl) then return end
         saver:ClientProp(!table.IsEmpty(saver.ClientProps), tbl)
      end
    end))

    AddButton(NGUI:Button('Place saving', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(saver.savePath..'/'..filename..'.txt','DATA') then
        local tbl = util.JSONToTable(file.Read(saver.savePath..'/'..filename..'.txt'))
        if !istable(tbl) then return end
        saver:SpawnEnts(tbl)
      end
    end))

    AddButton(NGUI:Button('Rename saving', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(saver.savePath..'/'..filename..'.txt','DATA') then
        local newName = edit:GetText()
        if newName == '' or newName == filename then return end
          NGUI:AcceptDialogue(l('Rename saving')..' '..filename
            ..' '..l('to')..' '..newName..'?', 'Yes', 'No', function()
            file.Rename(saver.savePath..'/'..filename..'.txt',saver.savePath..'/'..newName..'.txt')
            list:Upd() edit:Upd()
          end)
      end
    end))

    AddButton(NGUI:DeclineButton('Remove saving', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(saver.savePath..'/'..filename..'.txt','DATA') then
        NGUI:AcceptDialogue(l('Remove saving')..' '..filename..'?', 'Yes', 'No', function()
          file.Delete(saver.savePath..'/'..filename..'.txt')
          list:Upd()
        end)
      end
    end))

    AddButton(NGUI:Button('Update savings', function() list:Upd() end))

    AddButton(NGUI:Button('Clear selection', function()
      saver.Ents = {}
    end))
  end

  -- function TOOL:LeftClick(tr)
	--   return true
  -- end
  
  -- function TOOL:RightClick()
	--   return self:LeftClick(tr)
  -- end

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