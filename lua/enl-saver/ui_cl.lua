local freezeCvar = CreateClientConVar(ENL.Saver.freezeCvarName,'0',true,true)

function ENL.Saver:CreateUI(toolObj)
  local function AddButton(btn)
    local pnl = toolObj:Add('DPanel')
    pnl:SetTall(30)
    pnl:Dock(TOP)
    pnl:SetText('')
    pnl:DockMargin(20,10,20,0)
    
    btn:SetParent(pnl)
    btn:Dock(FILL)
  end

  toolObj:AddControl('Header', {Text = '#Tool.enl_saver.name', Description = '#Tool.enl_saver.desc'})

  local pnl = toolObj:Add('DPanel')
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
        while file.Exists(ENL.Saver.savePath..'/'..'Save '..num..'.txt','DATA') do
          num = num + 1
        end
        edit:SetText('Save '..num)
      end
    end
  end

  edit:Upd()

  AddButton(NGUI:AcceptButton('Save items', function()
    self:SaveEnts(edit:GetText())
    toolObj.SavesList:Upd()
    edit:Upd()
  end))

  toolObj:AddControl('CheckBox', {
    Label = l('Place with saving world positions'), Command = self.wPosCvar:GetName()
  })
  toolObj:AddControl('CheckBox', {
    Label = l('Freeze Items On Spawn'), Command = freezeCvar:GetName()
  })

  local list = vgui.Create('DListView', toolObj)
  list:SetTall(ScrH() / 3)
  list:Dock(TOP)
  list:DockMargin(0, 10, 0, 0)
  list:SetMultiSelect(false)
  list:AddColumn(l('Savings'))

  function list:Upd()
    list:Clear()
    local files = file.Find(ENL.Saver.savePath..'/*.txt','DATA')
    for _,f in pairs(files) do
      f = string.StripExtension(f)
      list:AddLine(f)
    end
  end
  list:Upd()
  toolObj.SavesList = list

  AddButton(NGUI:Button('Show/Hide structure', function()
    local sel = list:GetSelected()[1]
    if !sel then return end
    local filename = sel:GetColumnText(1)
    if file.Exists(self.savePath..'/'..filename..'.txt','DATA') then
      local tbl = util.JSONToTable(file.Read(self.savePath..'/'..filename..'.txt'))
      if !istable(tbl) then return end
        self:ClientProp(!table.IsEmpty(self.ClientProps), tbl)
    end
  end))

  AddButton(NGUI:Button('Place saving', function()
    local sel = list:GetSelected()[1]
    if !sel then return end
    local filename = sel:GetColumnText(1)
    if file.Exists(self.savePath..'/'..filename..'.txt','DATA') then
      local tbl = util.JSONToTable(file.Read(self.savePath..'/'..filename..'.txt'))
      if !istable(tbl) then return end
      self:SpawnEnts(tbl)
    end
  end))

  AddButton(NGUI:Button('Rename saving', function()
    local sel = list:GetSelected()[1]
    if !sel then return end
    local filename = sel:GetColumnText(1)
    if file.Exists(self.savePath..'/'..filename..'.txt','DATA') then
      local newName = edit:GetText()
      if newName == '' or newName == filename then return end
        NGUI:AcceptDialogue(l('Rename saving')..' '..filename
          ..' '..l('to')..' '..newName..'?', 'Yes', 'No', function()
          file.Rename(self.savePath..'/'..filename..'.txt',self.savePath..'/'..newName..'.txt')
          list:Upd() edit:Upd()
        end)
    end
  end))

  AddButton(NGUI:DeclineButton('Remove saving', function()
    local sel = list:GetSelected()[1]
    if !sel then return end
    local filename = sel:GetColumnText(1)
    if file.Exists(self.savePath..'/'..filename..'.txt','DATA') then
      NGUI:AcceptDialogue(l('Remove saving')..' '..filename..'?', 'Yes', 'No', function()
        file.Delete(self.savePath..'/'..filename..'.txt')
        list:Upd()
      end)
    end
  end))

  AddButton(NGUI:Button('Update savings', function() list:Upd() end))

  AddButton(NGUI:Button('Clear selection', function()
    self.Ents = {}
  end))
end