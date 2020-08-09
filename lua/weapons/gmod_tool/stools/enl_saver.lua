TOOL.Category = 'Construction'
TOOL.Name = '#tool.enl_saver.name'

local netstr = 'ENL Saver'

ENL = ENL or {}
ENL.Saver = ENL.Saver or {}

function ENL.Saver:CanProceedEnt(ply,ent)
  if !IsValid(ply) or !IsValid(ent) then return end
  local function Note(text) ply:PrintMessage(HUD_PRINTCENTER,text) end
  if !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then
    Note('Предмет должен быть пропом')
    return
  end
  if ply:GetPos():Distance(ent:GetPos()) > NCfg:Get('Saver','Max. Items Spawn Distance') then
    Note('Слишком большое расстояние до предмета') return false end
  local tr = util.TraceLine({start=ply:EyePos(),endpos=ent:WorldSpaceCenter(),
    filter = function(e) if e.SID != ply.SID then return true end end
  })
  -- if tr.Hit then Note('Предмет вне поля видимости') return false end
  for _,ent in pairs(ents.FindInSphere(ent:GetPos(),ent:BoundingRadius() or 50)) do
    if ent:IsPlayer() then Note('Игрок блокирует спавн предмета') return false end
  end
  return true
end

local function GetEntID(ent) return ent:GetCreationID() end

if SERVER then

  util.AddNetworkString(netstr)

	function TOOL:LeftClick(tr)
	  local ent,ply = tr.Entity,self:GetOwner()
	  if !table.HasValue(NCfg:Get('Saver','Classes To Save'), ent:GetClass()) then return false end
    net.Start(netstr)
    net.WriteBool(false)
    net.WriteEntity(ent)
    net.Send(ply)
	  return true
	end

	function TOOL:RightClick(tr)
	  return self:LeftClick(tr)
	end

  function TOOL:Reload(tr)
    local ply = self:GetOwner()
    net.Start(netstr)
    net.WriteBool(true)
    net.Send(ply)
  end

  local firstEnts = {}

  net.Receive(netstr,function(len,ply)
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
      phys:EnableMotion(false)
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

  local path = 'enl_saver/saves'
  local convar = CreateClientConVar('enl_saver_worldposspawns','0')

  language.Add('Tool.enl_saver.name', l('Saver'))
  language.Add('Tool.enl_saver.desc', l('Saves groups of items'))
  language.Add('Tool.enl_saver.0', l('Click on any of items to add / remove it from the bunch'))

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
      NGUI:AcceptDialogue('Перезаписать уже имеющийся файл '..filename..'?', 'Да', 'Нет', Write)
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
    local useWPos = convar:GetBool()
    for i,data in pairs(tbl) do
      timer.Simple(GetSpawnDelay()*(i-1),function()
        if ENL.Saver.Abort then return end
        net.Start(netstr)
        if !useWPos then data.wpos = nil end
        if i == 1 then data.firstEnt = true end
        data.useWPos = (useWPos or nil)
        net.WriteTable(data)
        net.SendToServer()
      end)
    end
  end

  hook.Add('HUDPaint','NL Dulpicator Progress',function()
    if !ENL.Saver.InProgress or ENL.Saver.Abort then return end
    local text = 'Сохранятор создает объект... '..math.Round(timer.TimeLeft('NL Duplicator Progress Timer'),1)
    local txtdata = {text=text,font='DermaLarge',pos={ScrW()-400,ScrH()/15},color=Color(255,255,255)}
    draw.Text(txtdata)
    draw.TextShadow(txtdata,2,200)
    txtdata.text = 'Нажмите R, чтобы отменить создание'
    txtdata.pos = {ScrW()-510,ScrH()/10}
    draw.Text(txtdata)
    draw.TextShadow(txtdata,2,200)
    if ENL.Saver.InProgress and LocalPlayer():KeyPressed(IN_RELOAD) then
      ENL.Saver.Abort = true
    end
  end)

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
    AddButton(NGUI:AcceptButton('Сохранить предметы', function()
      ENL.Saver:SaveEnts(edit:GetText())
			self.SavesList:Upd()
      edit:Upd()
    end))

    self:AddControl('CheckBox', {Label = 'Размещать, сохраняя позиции на карте', Command = convar:GetName()})

    local list = vgui.Create('DListView', self)
    list:SetTall(ScrH() / 3)
    list:Dock(TOP)
    list:DockMargin(0, 10, 0, 0)
    list:SetMultiSelect(false)
    list:AddColumn('Сохранения')

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

    AddButton(NGUI:Button('Разместить сохранение', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        local tbl = util.JSONToTable(file.Read(path..'/'..filename..'.txt'))
        if !istable(tbl) then return end
        ENL.Saver:SpawnEnts(tbl)
      end
    end))

    AddButton(NGUI:Button('Переименовать сохранение', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        local newName = edit:GetText()
        if newName == '' or newName == filename then return end
          NGUI:AcceptDialogue('Переименовать сохранение '..filename..' в '..newName..'?', 'Да', 'Нет', function()
            file.Rename(path..'/'..filename..'.txt',path..'/'..newName..'.txt')
            list:Upd() edit:Upd()
          end)
      end
    end))

    AddButton(NGUI:DeclineButton('Удалить сохранение', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        NGUI:AcceptDialogue('Удалить сохранение '..filename..'?', 'Да', 'Нет', function()
          file.Delete(path..'/'..filename..'.txt')
          list:Upd()
        end)
      end
    end))

    AddButton(NGUI:Button('Обновить сохранения', function() list:Upd() end))

  end

  net.Receive(netstr, function()
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

  hook.Add('PreDrawHalos', 'ENL Duplicator Draw', function()
    if table.Count(ENL.Saver.Ents) > 0 then
      local wep, tool = LocalPlayer():GetActiveWeapon(), LocalPlayer():GetTool()
	    if !IsValid(wep) or wep:GetClass() != 'gmod_tool'
	      or tool.Mode != 'enl_saver' then return end
    
	    local haloEnts = {}
	    for ent, bool in pairs(ENL.Saver.Ents) do
	      if bool and IsValid(ent) then table.insert(haloEnts, ent)
	      else ENL.Saver.Ents[ent] = nil end
	    end
	    halo.Add(haloEnts, Color(0, 255, 0), 10, 10, 1)
		end
  end)

end
