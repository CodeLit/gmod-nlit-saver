hook.Add('HUDPaint','ENL Dulpicator Progress',function()
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

hook.Add('PreDrawHalos', 'ENL Duplicator Draw', function()
  if !table.IsEmpty(ENL.Saver.Ents) then
    local wep, tool = LocalPlayer():GetActiveWeapon(), LocalPlayer():GetTool()
    if !IsValid(wep) or wep:GetClass() != 'gmod_tool'
      or tool.Mode != 'enl_saver' then return end
  
    local haloEnts = {}
    for ent, bool in pairs(ENL.Saver.Ents) do
      if bool and IsValid(ent) then table.insert(haloEnts, ent)
      else ENL.Saver.Ents[ent] = nil end
    end
    halo.Add(haloEnts, Color( 51, 255, 51 ), 1, 1, 15, true, true)
  end

  if !table.IsEmpty(ENL.Saver.ClientProps) then
    local haloEnts = {}
    for _, ent in pairs(ENL.Saver.ClientProps) do
      table.insert(haloEnts, ent)
    end
    halo.Add(haloEnts, NC:White(), 1, 1, 15, true, true)
  end
end)