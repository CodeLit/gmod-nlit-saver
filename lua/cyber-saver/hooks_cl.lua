-- [do not obfuscate]

local saver = CW.Saver

hook.Add('HUDPaint','ENL Dulpicator Progress',function()
  if !saver.InProgress or saver.Abort then return end
  local text = l('Saver is creating objects')..'...'
    ..math.Round(timer.TimeLeft('NL Duplicator Progress Timer'),1)
  local txtdata = {text=text,font='DermaLarge',pos={ScrW()-450,ScrH()/15},color=Color(255,255,255)}
  draw.Text(txtdata)
  draw.TextShadow(txtdata,2,200)
  txtdata.text = l('Press R button to reject creation')..'.'
  txtdata.pos = {ScrW()-510,ScrH()/10}
  draw.Text(txtdata)
  draw.TextShadow(txtdata,2,200)
  if saver.InProgress and LocalPlayer():KeyPressed(IN_RELOAD) then
    saver.Abort = true
  end
end)

hook.Add('PreDrawHalos', 'ENL Duplicator Draw', function()

  if !saver:IsPlyHolding(LocalPlayer()) then return end

  if !table.IsEmpty(saver.Ents) then
    local haloEnts = {}
    for ent, bool in pairs(saver.Ents) do
      if bool and IsValid(ent) then table.insert(haloEnts, ent)
      else saver.Ents[ent] = nil end
    end
    halo.Add(haloEnts, Color( 51, 255, 51 ), 1, 1, 15, true, true)
  end

  if !table.IsEmpty(saver.ClientProps) then
    local haloWhiteEnts = {}
    local haloRedEnts = {}
    for _, ent in pairs(saver.ClientProps) do
      if ent:GetNoDraw() then
        table.insert(haloRedEnts, ent)
      else
        table.insert(haloWhiteEnts, ent)
      end
    end
    halo.Add(haloWhiteEnts, NC:White(), 1, 1, 15, true, true)
    halo.Add(haloRedEnts, NC:Red(), 1, 1, 15, true, true)
  end
end)
