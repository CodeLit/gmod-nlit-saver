TOOL.Category = "Construction"
TOOL.Name = "#tool.nl_duplicator.name"

local maxRange,coolDown,delayBetweenSpawns = 500,5,0.5

local netstr = 'NL Duplicator'

NL = NL or {}
NL.Duplicator = NL.Duplicator or {}

function NL.Duplicator:CanProceedEnt(ply,ent)
  if !IsValid(ply) or !IsValid(ent) then return end
  local function Note(text) ply:PrintMessage(HUD_PRINTCENTER,text) end
  if ent:GetClass() != 'prop_physics' then Note('Предмет должен быть пропом') return end
  if ply:GetPos():Distance(ent:GetPos()) > maxRange then Note('Слишком большое расстояние до предмета') return false end
  local tr = util.TraceLine({start=ply:EyePos(),endpos=ent:WorldSpaceCenter(),
    filter = function(e) if e.SID != ply.SID then return true end end
  })
  if tr.Hit then Note('Предмет вне поля видимости') return false end
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
	  if ent:GetClass() != 'prop_physics' then return false end
    net.Start(netstr)
    net.WriteEntity(ent)
    net.Send(ply)
	  return true
	end

	function TOOL:RightClick(tr)
	  return self:LeftClick(tr)
	end

  local firstEnts = {}

  net.Receive(netstr,function(len,ply)
    local data = net.ReadTable()
    if !(isvector(data.wpos) or isvector(data.lpos))
    or !isangle(data.wang) or !isstring(data.mdl) then return end
    if !hook.Run("PlayerSpawnProp",ply,data.mdl) then return end
    local prop = ents.Create('prop_physics')
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
    if !NL.Duplicator:CanProceedEnt(ply,prop) then prop:Remove() return end
    prop:CPPISetOwner(ply)
    prop.SID = ply.SID
    prop:Spawn()

    prop:SetVar("Unbreakable",true)
    prop:Fire("SetDamageFilter","FilterDamage",0)

    gamemode.Call("PlayerSpawnedProp",ply,data.mdl,prop)

		cleanup.Add(ply,"props",prop)
		undo.Create("prop")
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
    local addTime = delayBetweenSpawns or 0.5
    if NL and NL.CustomNet and NL.CustomNet.GetDelayBetweenSameNetStrings then
      addTime = addTime + NL.CustomNet.GetDelayBetweenSameNetStrings()
    end
    return addTime
  end

  NL.Duplicator.Ents = NL.Duplicator.Ents or {}

  local path = 'nl_duplicator/saves'
  local convar = CreateClientConVar('nl_duplicator_worldposspawns','0')

  language.Add("Tool.nl_duplicator.name", "Сохранятор")
  language.Add("Tool.nl_duplicator.desc", "Сохраняет связки предметов")
  language.Add("Tool.nl_duplicator.0", "Нажмите на любой предмет, чтобы добавить / удалить его из связки")

	local function DialogueWindow(question,...)

		local fr = vgui.Create('DFrame')
		fr:SetTitle('')

		local label = Label(question,fr)
		label:SetFont('Trebuchet24')
		label:Dock(TOP)
		label:SetContentAlignment(5)
    label:SizeToContents()

    fr:SetSize((label:GetWide()+30)*1.2,65)
    fr:Center()
    fr:MakePopup()

		local function AddButton(text,f)
      local btn = fr:Add("DButton")
      btn:Dock(TOP)
			btn:SetTall(30)
      btn:SetText(text)
      btn.DoClick = function(btn)
        if f then f(btn) end
        fr:Close()
      end
			btn:DockMargin(20,10,20,0)
			fr:SetTall(fr:GetTall()+40)
    end
		for _,data in pairs({...}) do AddButton(data.text,data.func) end
	end

	function NL.Duplicator:SaveEnts(filename)
    if !file.IsDir(path,'DATA') then file.CreateDir(path) end
    local function Write()
      if table.Count(NL.Duplicator.Ents) <= 0 then return end
      local tbl = {[1]=false}
      for ent,_ in pairs(NL.Duplicator.Ents) do
        local instbl = {mdl = ent:GetModel()}
        instbl.ent = ent
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
      DialogueWindow('Перезаписать уже имеющийся файл '..filename..'?',{text="Да",func=Write},{text="Нет"})
		else Write() end
	end

  NL.Duplicator.LastSpawn = NL.Duplicator.LastSpawn or CurTime()

  function NL.Duplicator:SpawnEnts(tbl)
    local coolDownTimeLeft = math.Round((NL.Duplicator.LastSpawn + coolDown)-CurTime(),1)
    if coolDownTimeLeft >= 0 then
      LocalPlayer():ChatPrint('Сохранятор не может работать так часто. Осталось '..coolDownTimeLeft..' сек.')
      return
    end
    if NL.Duplicator.InProgress then return end
    NL.Duplicator.InProgress = true
    timer.Create('NL Duplicator Progress Timer',(GetSpawnDelay()*table.Count(tbl)),1,function()
      NL.Duplicator.LastSpawn = CurTime()
      NL.Duplicator.InProgress = nil
      NL.Duplicator.Abort = nil
    end)
    local useWPos = convar:GetBool()
    for i,data in pairs(tbl) do
      timer.Simple(GetSpawnDelay()*(i-1),function()
        if NL.Duplicator.Abort then return end
        net.Start(netstr)
        if useWpos then data.lpos = nil
        else data.wpos = nil end
        if i == 1 then data.firstEnt = true end
        data.useWPos = (useWpos or nil)
        net.WriteTable(data)
        net.SendToServer()
      end)
    end
  end

  hook.Add('HUDPaint','NL Dulpicator Progress',function()
    if !NL.Duplicator.InProgress or NL.Duplicator.Abort then return end
    local text = 'Сохранятор создает объект... '..math.Round(timer.TimeLeft('NL Duplicator Progress Timer'),1)
    local txtdata = {text=text,font='DermaLarge',pos={ScrW()-400,ScrH()/15},color=Color(255,255,255)}
    draw.Text(txtdata)
    draw.TextShadow(txtdata,2,200)
    txtdata.text = 'Нажмите R, чтобы отменить создание'
    txtdata.pos = {ScrW()-510,ScrH()/10}
    draw.Text(txtdata)
    draw.TextShadow(txtdata,2,200)
    if NL.Duplicator.InProgress and LocalPlayer():KeyPressed(IN_RELOAD) then
      NL.Duplicator.Abort = true
    end
  end)

  function TOOL:BuildCPanel()

    local function AddButton(text, func)
      local pnl = self:Add("DPanel")
      pnl:SetTall(30)
      pnl:Dock(TOP)
			pnl:DockMargin(20,10,20,0)

      local btn = pnl:Add("DButton")
      btn:Dock(FILL)
      btn:SetText(text)
      btn:SetFont('Trebuchet18')
      btn.DoClick = func
    end

    self:AddControl("Header", {Text = "#Tool.nl_duplicator.name", Description = "#Tool.nl_duplicator.desc"})

		local pnl = self:Add("DPanel")
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
    AddButton('Сохранить предметы', function()
      NL.Duplicator:SaveEnts(edit:GetText())
			self.SavesList:Upd()
      edit:Upd()
    end)

    self:AddControl("CheckBox", {Label = "Размещать, сохраняя позиции на карте", Command = convar:GetName()})

    local list = vgui.Create("DListView", self)
    list:SetTall(ScrH() / 3)
    list:Dock(TOP)
    list:DockMargin(0, 10, 0, 0)
    list:SetMultiSelect(false)
    list:AddColumn("Сохранения")

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

		AddButton('Обновить сохранения', function() list:Upd() end)

    AddButton('Разместить сохранение', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        local tbl = util.JSONToTable(file.Read(path..'/'..filename..'.txt'))
        if !istable(tbl) then return end
        NL.Duplicator:SpawnEnts(tbl)
      end
    end)

    AddButton('Переименовать сохранение', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        local newName = edit:GetText()
        if newName == '' or newName == filename then return end
        DialogueWindow('Переименовать сохранение '..filename..' в '..newName..'?',
        {text="Да",func=function()
          file.Rename(path..'/'..filename..'.txt',path..'/'..newName..'.txt')
          list:Upd() edit:Upd()
        end},{text="Нет"})
      end
    end)

    AddButton('Удалить сохранение', function()
      local sel = list:GetSelected()[1]
      if !sel then return end
      local filename = sel:GetColumnText(1)
      if file.Exists(path..'/'..filename..'.txt','DATA') then
        DialogueWindow('Удалить сохранение '..filename..'?',{text="Да",func=function()
          file.Delete(path..'/'..filename..'.txt')
          list:Upd()
        end},{text="Нет"})
      end
    end)

  end

  net.Receive(netstr, function()
    local ent = net.ReadEntity()
    if IsValid(ent) then
      if NL.Duplicator.Ents[ent] then NL.Duplicator.Ents[ent] = nil
      else NL.Duplicator.Ents[ent] = true end
    end
  end)

  hook.Add('PreDrawHalos', 'NL Duplicator Draw', function()
    if table.Count(NL.Duplicator.Ents) > 0 then
	    local wep, tool = LocalPlayer():GetActiveWeapon(), LocalPlayer():GetTool()
	    if !IsValid(wep) or wep:GetClass() != 'gmod_tool'
	    or tool.Mode != 'nl_duplicator' then return end
	    local haloEnts = {}
	    for ent, bool in pairs(NL.Duplicator.Ents) do
	      if bool and IsValid(ent) then table.insert(haloEnts, ent)
	      else NL.Duplicator.Ents[ent] = nil end
	    end
	    halo.Add(haloEnts, Color(0, 255, 0), 10, 10, 1)
		end
  end)

end
