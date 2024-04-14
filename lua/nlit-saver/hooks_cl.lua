local l = nlitLib:Load('lang')
local NC = nlitColor
hook.Add('HUDPaint', 'ENL Dulpicator Progress', function()
  if not nlitSaver.InProgress or nlitSaver.Abort then return end
  local text = l('Saver is creating objects') .. '...' .. math.Round(timer.TimeLeft('NL Duplicator Progress Timer'), 1)
  local txtdata = {
    text = text,
    font = 'DermaLarge',
    pos = {ScrW() - 450, ScrH() / 15},
    color = Color(255, 255, 255)
  }

  draw.Text(txtdata)
  draw.TextShadow(txtdata, 2, 200)
  txtdata.text = l('Press R button to reject creation') .. '.'
  txtdata.pos = {ScrW() - 510, ScrH() / 10}
  draw.Text(txtdata)
  draw.TextShadow(txtdata, 2, 200)
  if nlitSaver.InProgress and LocalPlayer():KeyPressed(IN_RELOAD) then nlitSaver.Abort = true end
end)

hook.Add('PreDrawHalos', 'ENL Duplicator Draw', function()
  if not nlitSaver:IsPlyHolding(LocalPlayer()) then return end
  if not table.IsEmpty(nlitSaver.Ents) then
    local haloEnts = {}
    for ent, bool in pairs(nlitSaver.Ents) do
      if bool and IsValid(ent) then
        table.insert(haloEnts, ent)
      else
        nlitSaver.Ents[ent] = nil
      end
    end

    halo.Add(haloEnts, Color(51, 255, 51), 1, 1, 15, true, true)
  end

  if not table.IsEmpty(nlitSaver.ClientProps) then
    local haloWhiteEnts = {}
    local haloRedEnts = {}
    for _, ent in pairs(nlitSaver.ClientProps) do
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

nlitSaver:debug('HOOKS LOADED!')