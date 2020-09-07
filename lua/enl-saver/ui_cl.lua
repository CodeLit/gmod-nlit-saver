-- [do not obfuscate]

local saver = ENL.Saver

local freezeCvar = CreateClientConVar(saver.freezeCvarName,'0',true,true)

function saver:CreateUI(toolObj)

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

  local saveText = l('Save')

  local edit = vgui.Create('DTextEntry',pnl)
  edit:Dock(FILL)
  edit:SetText(saveText..' '..'1')
  edit:SelectAllOnFocus()
  
  function edit:Upd()
    local txt = edit:GetText()
    local exp = string.Explode(' ',txt)
    if string.find(txt,saveText..' ') == 1 and exp[2] then
      local num = tonumber(exp[2])
      if isnumber(num) then
        local svs = saver:GetSaves()
        while svs[saveText..' '..num] do
          num = num + 1
        end
        edit:SetText(saveText..' '..num)
      end
    end
  end

  edit:Upd()

  AddButton(NGUI:AcceptButton('Save items', function()
    saver:SaveEnts(edit:GetText())
    ENL.Saver.savesList:Upd()
    edit:Upd()
  end))

  toolObj:AddControl('CheckBox', {
    Label = l('Place with saving world positions'), Command = saver.wPosCvar:GetName()
  })
  toolObj:AddControl('CheckBox', {
    Label = l('Freeze Items On Spawn'), Command = freezeCvar:GetName()
  })
  toolObj:AddControl('CheckBox', {
    Label = l('Preview'), Command = saver.previewCvar:GetName()
  })

  local saves = vgui.Create('DListView', toolObj)
  saves:SetTall(ScrH() / 3)
  saves:Dock(TOP)
  saves:DockMargin(0, 10, 0, 0)
  saves:SetMultiSelect(false)
  saves:AddColumn(l('Savings'))
  ENL.Saver.savesList = saves

  function saves:Upd()
    self:Clear()
    for s,_ in pairs(saver:GetSaves()) do
      self:AddLine(s)
    end
  end

  saves:Upd()

  AddButton(NGUI:Button('Place saving', function()
    local sel = saves:GetSelected()[1]
    if !sel then return end
    local saveName = sel:GetColumnText(1)
    local saves = saver:GetSaves()
    if saver:SaveExists(saveName) then
      saver:SpawnEnts(saves[saveName])
    end
  end))

  AddButton(NGUI:Button('Rename saving', function()
    local sel = saves:GetSelected()[1]
    if !sel then return end
    local saveName = sel:GetColumnText(1)
    if saver:SaveExists(saveName) then
      local newName = edit:GetText()
      if newName == '' or newName == saveName then return end
        NGUI:AcceptDialogue(l('Rename saving')..' '..saveName
          ..' '..l('to')..' '..newName..'?', 'Yes', 'No', function()
          saver:RenameSave(saveName,newName)
          saves:Upd()
          edit:Upd()
        end)
    end
  end))

  AddButton(NGUI:DeclineButton('Remove saving', function()
      local sel = saves:GetSelected()[1]
      if !sel then return end
      local saveName = sel:GetColumnText(1)
      if saver:SaveExists(saveName) then
          NGUI:AcceptDialogue(l('Remove saving')..' '..saveName..'?', 'Yes', 'No', function()
          saver:RemoveSave(saveName)
          saves:Upd()
          end)
      end
  end))

  AddButton(NGUI:Button('Clear selection', function()
    saver.Ents = {}
  end))

  if LocalPlayer():IsSuperAdmin() then
    toolObj:AddControl('Slider', {
      Label = l('Max props')..' ['..l('Admins')..']', Command = 'sbox_maxprops'
    })
  end
end