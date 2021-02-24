-- [do not obfuscate]

local freezeCvar = CreateClientConVar(CWSaver.freezeCvarName,'0',true,true)

local l = CW:Lib('translator')
local Buttons = CW:Lib('buttons')
local Frames = CW:Lib('frames')

function CWSaver:CreateUI(toolObj)
  local function AddButton(btn)
    local pnl = toolObj:Add('DPanel')
    pnl:SetTall(30)
    pnl:Dock(TOP)
    pnl:SetText('')
    pnl:DockMargin(20,10,20,0)
    btn:SetParent(pnl)
    btn:Dock(FILL)
  end
  toolObj:AddControl('Header', {Text = '#Tool.'..self.tool..'.name', Description = '#Tool.'..self.tool..'.desc'})
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
        local svs = CWSaver:GetSaves()
        while svs[saveText..' '..num] do
          num = num + 1
        end
        edit:SetText(saveText..' '..num)
      end
    end
  end

  edit:Upd()

  AddButton(Buttons:Accept('Save items', function()
    self:SaveEnts(edit:GetText())
    self.savesList:Upd()
    edit:Upd()
  end))

  toolObj:AddControl('CheckBox', {
    Label = l('Place with saving world positions'), Command = self.wPosCvar:GetName()
  })
  toolObj:AddControl('CheckBox', {
    Label = l('Freeze Items On Spawn'), Command = freezeCvar:GetName()
  })
  toolObj:AddControl('CheckBox', {
    Label = l('Preview'), Command = self.previewCvar:GetName()
  })
  local saves = vgui.Create('DListView', toolObj)
  saves:SetTall(ScrH() / 3)
  saves:Dock(TOP)
  saves:DockMargin(0, 10, 0, 0)
  saves:SetMultiSelect(false)
  saves:AddColumn(l('Savings'))
  saves.OnRowSelected = function(rowIndex, row)
    self:ClearClientProps()
  end
  self.savesList = saves

  function saves:Upd()
    self:Clear()
    for s,_ in pairs(CWSaver:GetSaves()) do
      self:AddLine(s)
    end
  end

  saves:Upd()

  AddButton(Buttons:Create('Place saving', function()
    local sel = saves:GetSelected()[1]
    if !sel then return end
    local saveName = sel:GetColumnText(1)
    local svs = self:GetSaves()
    if self:SaveExists(saveName) then
      self:SpawnEnts(svs[saveName])
    end
  end))

  AddButton(Buttons:Create('Rename saving', function()
    local sel = saves:GetSelected()[1]
    if !sel then return end
    local saveName = sel:GetColumnText(1)
    if self:SaveExists(saveName) then
      local newName = edit:GetText()
      if newName == '' or newName == saveName then return end
        Frames:AcceptDialogue(l('Rename saving')..' '..saveName
          ..' '..l('to')..' '..newName..'?', 'Yes', 'No', function()
          self:RenameSave(saveName,newName)
          saves:Upd()
          edit:Upd()
        end)
    end
  end))

  AddButton(Buttons:Decline('Remove saving', function()
      local sel = saves:GetSelected()[1]
      if !sel then return end
      local saveName = sel:GetColumnText(1)
      if self:SaveExists(saveName) then
          Frames:AcceptDialogue(l('Remove saving')..' '..saveName..'?', 'Yes', 'No', function()
            self:RemoveSave(saveName)
            saves:Upd()
          end)
      end
  end))

  AddButton(Buttons:Create('Clear selection', function()
    self.Ents = {}
  end))

  if LocalPlayer():IsSuperAdmin() then
    toolObj:AddControl('Slider', {
      Label = l('Max props')..' ['..l('Admins')..']', Command = 'sbox_maxprops'
    })
  end
end

CWSaver:debug('UI LOADED!')