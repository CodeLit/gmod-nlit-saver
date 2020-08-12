TOOL.Category = 'Construction'
TOOL.Name = '#tool.enl_saver.name'

if SERVER then

	function TOOL:LeftClick(tr)
	  local ent,ply = tr.Entity,self:GetOwner()
	  if !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then return false end
    net.Start(ENL.Saver.netstr)
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

  local firstEnts = {}

  net.Receive(ENL.Saver.netstr,function(_,ply)
    local data = net.ReadTable()
    if !(isvector(data.wpos) or isvector(data.lpos))
    or !isangle(data.wang) or !isstring(data.mdl) then return end
    if !hook.Run('PlayerSpawnProp',ply,data.mdl) then return end
    local prop = ents.Create(data.class)
    if data.useWPos then
      prop:SetPos(data.wpos)
      prop:SetAngles(data.wang)
    else
      local ang = ply:EyeAngles()
      ang:RotateAroundAxis(ply:GetRight(),-90)
      prop:SetAngles(Angle(0,ang.y,0))
      if data.firstEnt then
        local trace = ply:GetEyeTrace()
        prop:SetPos(trace.HitPos)
      else
        local fent = firstEnts[ply:SteamID()]
        if !IsValid(fent) then return end
        prop:SetPos(fent:LocalToWorld(data.lpos))
        prop:SetAngles(fent:LocalToWorldAngles(data.lang))
      end
    end
    prop:SetModel(data.mdl)
    if !ENL.Saver:CanProceedEnt(ply,prop) then prop:Remove() return end
    if prop.CPPISetOwner then
      prop:CPPISetOwner(ply)
    end
    prop.SID = ply.SID
    prop:Spawn()
    if NCfg:Get('Saver','Create Indestructible Items') then
      prop:SetVar('Unbreakable',true)
      prop:Fire('SetDamageFilter','FilterDamage',0)
    end

    gamemode.Call('PlayerSpawnedProp',ply,data.mdl,prop)

		cleanup.Add(ply,'props',prop)
		undo.Create('prop')
		undo.AddEntity(prop)
		undo.SetPlayer(ply)
		undo.Finish()

    local phys = prop:GetPhysicsObject()
    if phys then
      if data.firstEnt and !data.useWPos then
        local mins,maxs = phys:GetAABB()
        prop:SetPos(prop:GetPos()+Vector(0,0,maxs.z+10))
      end
      phys:EnableMotion(!tobool(ply:GetInfo(ENL.Saver.freezeCvarName)))
    end

    if APA and APA.InitGhost then
      timer.Simple(1,function()
        APA.InitGhost(prop,true,false,false,true) -- ent,ghostoff,nofreeze,collision,forcefreeze
      end)
    end
    if data.mat and data.mat != prop:GetMaterial() then prop:SetMaterial(data.mat) end
    local color = (data.col and Color(data.col.r,data.col.g,data.col.b,data.col.a))
    if IsColor(color) then prop:SetColor(color) end
    if data.firstEnt then
      firstEnts[ply:SteamID()] = prop
      prop:DropToFloor()
    end
  end)

elseif CLIENT then

  local function GetSpawnDelay()
    local addTime = NCfg:Get('Saver','Delay Between Single Propspawn')
    if NL and NL.CustomNet and NL.CustomNet.GetDelayBetweenSameNetStrings then
      addTime = addTime + NL.CustomNet.GetDelayBetweenSameNetStrings()
    end
    return addTime
  end

  ENL.Saver.Ents = ENL.Saver.Ents or {}

  ENL.Saver.ClientProps = ENL.Saver.ClientProps or {}

  local path = 'enl_saver/saves'
  local wPosCvar = CreateClientConVar('enl_saver_worldposspawns','0')
  local freezeCvar = CreateClientConVar(ENL.Saver.freezeCvarName,'0',true,true)

  language.Add('Tool.enl_saver.name', l('Saver'))
  language.Add('Tool.enl_saver.desc', l('Saves groups of items'))
  language.Add('Tool.enl_saver.0', l('Click on any of items to add / remove it from the bunch. Press [R] to unselect all')..'.')

	function ENL.Saver:SaveEnts(filename)
    if !file.IsDir(path,'DATA') then file.CreateDir(path) end
    local function Write()
      if table.Count(ENL.Saver.Ents) <= 0 then return end
      local tbl = {[1]=false}
      for ent,_ in pairs(ENL.Saver.Ents) do
        local instbl = {mdl = ent:GetModel()}
        instbl.ent = ent
        instbl.class = ent:GetClass()
        instbl.wpos = ent:GetPos()
        instbl.wang = ent:GetAngles()
        instbl.mat = ent:GetMaterial()
        local clr = ent:GetColor()
        if clr != Color(255,255,255) then instbl.col = clr end
        table.insert(tbl,instbl)
      end
      local rmID
      for i,data in pairs(tbl) do // записать первый элемент как самый низкий по Z
        if i != 1 then
          if !tbl[1] then tbl[1] = data end
          if data.wpos.z <= tbl[1].wpos.z then
            tbl[1] = data
            rmID = i
          end
        end
      end
      for i,data in pairs(tbl) do
        if i == 1 then data.lpos = data.wpos data.lang = data.wang
        else
          data.lpos = tbl[1].ent:WorldToLocal(data.wpos)
          data.lang = tbl[1].ent:WorldToLocalAngles(data.wang)
        end
      end
      table.remove(tbl,rmID)
      file.Write(path..'/'..filename..'.txt',util.TableToJSON(tbl))
    end
    if file.Exists(path..'/'..filename..'.txt','DATA') then
      NGUI:AcceptDialogue('Перезаписать уже имеющийся файл '..filename..'?', 'Yes', 'No', Write)
    else
      Write()
    end
	end

  ENL.Saver.LastSpawn = ENL.Saver.LastSpawn or CurTime()

  function ENL.Saver:SpawnEnts(tbl)
    local coolDownTimeLeft = math.Round((ENL.Saver.LastSpawn + NCfg:Get('Saver','Save Cooldown'))-CurTime(),1)
    if coolDownTimeLeft >= 0 then
      LocalPlayer():ChatPrint('Сохранятор не может работать так часто. Осталось '..coolDownTimeLeft..' сек.')
      return
    end
    if ENL.Saver.InProgress then return end
    ENL.Saver.InProgress = true
    timer.Create('NL Duplicator Progress Timer',(GetSpawnDelay()*table.Count(tbl)),1,function()
      ENL.Saver.LastSpawn = CurTime()
      ENL.Saver.InProgress = nil
      ENL.Saver.Abort = nil
    end)
    local useWPos = wPosCvar:GetBool()
    for i,data in pairs(tbl) do
      timer.Simple(GetSpawnDelay()*(i-1),function()
        if ENL.Saver.Abort then return end
        net.Start(ENL.Saver.netstr)
        if !useWPos then data.wpos = nil end
        if i == 1 then data.firstEnt = true end
        data.useWPos = (useWPos or nil)
        net.WriteTable(data)
        net.SendToServer()
      end)
    end
    ENL.Saver:ClientProp(true)
  end

   function ENL.Saver:ClientProp(bDelete, tbl)
      if !bDelete then
         for i, data in pairs(tbl) do
            local client = ents.CreateClientProp(data.mdl)
            client:SetPos(data.wpos)
            client:SetAngles(data.wang)
            client:Spawn()

            table.insert(ENL.Saver.ClientProps, client)
         end
      else
         if !table.IsEmpty(ENL.Saver.ClientProps) then
            for _, ent in pairs(ENL.Saver.ClientProps) do
             if IsValid(ent) then
               	ent:Remove()
             else
								ENL.Saver.ClientProps = {}
             end
            end
            ENL.Saver.ClientProps = {}
         end
      end 
   end

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
          while file.Exists(path..'/'..'Save '..num..'.txt','DATA') do num = num + 1 end
          edit:SetText('Save '..num)
        end
      end
    end

    edit:Upd()

    AddButton(NGUI:AcceptButton('Save items', function()
      ENL.Saver:SaveEnts(edit:GetText())
			self.SavesList:Upd()
      edit:Upd()
    end))

    self:AddControl('CheckBox', {Label = l('Place with saving world positions'), Command = wPosCvar:GetName()})

    self:AddControl('CheckBox', {Label = l('Freeze Items On Spawn'), Command = freezeCvar:GetName()})

    local list = vgui.Create('DListView', self)
    list:SetTall(ScrH() / 3)
    list:Dock(TOP)
    list:DockMargin(0, 10, 0, 0)
    list:SetMultiSelect(false)
    list:AddColumn(l('Savings'))

		function list:Upd()
			list:Clear()
      local files = file.Find(path..'/*.txt','DATA')
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
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        local tbl = util.JSONToTable(file.Read(path..'/'..filename..'.txt'))
        if !istable(tbl) then return end
         ENL.Saver:ClientProp(!table.IsEmpty(ENL.Saver.ClientProps), tbl)
      end
    end))

    AddButton(NGUI:Button('Place saving', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        local tbl = util.JSONToTable(file.Read(path..'/'..filename..'.txt'))
        if !istable(tbl) then return end
        ENL.Saver:SpawnEnts(tbl)
      end
    end))

    AddButton(NGUI:Button('Rename saving', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        local newName = edit:GetText()
        if newName == '' or newName == filename then return end
          NGUI:AcceptDialogue(l('Rename saving')..' '..filename
            ..' '..l('to')..' '..newName..'?', 'Yes', 'No', function()
            file.Rename(path..'/'..filename..'.txt',path..'/'..newName..'.txt')
            list:Upd() edit:Upd()
          end)
      end
    end))

    AddButton(NGUI:DeclineButton('Remove saving', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        NGUI:AcceptDialogue(l('Remove saving')..' '..filename..'?', 'Yes', 'No', function()
          file.Delete(path..'/'..filename..'.txt')
          list:Upd()
        end)
      end
    end))

    AddButton(NGUI:Button('Update savings', function() list:Upd() end))

    AddButton(NGUI:Button('Clear selection', function()
      ENL.Saver.Ents = {}
    end))
  end

  net.Receive(ENL.Saver.netstr, function()
    local doempty = net.ReadBool()
    local ent = net.ReadEntity()
    if !doempty then
      if IsValid(ent) then
        if ENL.Saver.Ents[ent] then ENL.Saver.Ents[ent] = nil
        else ENL.Saver.Ents[ent] = true end
      end
    else
      for ent, _ in pairs(ENL.Saver.Ents) do
        ENL.Saver.Ents[ent] = nil
      end
    end
  end)

  -- function TOOL:LeftClick(tr)
	--   return true
  -- end
  
  -- function TOOL:RightClick()
	--   return self:LeftClick(tr)
  -- end
  
  function TOOL:Reload()
    ENL.Saver.Ents = {}
    return true
  end

end