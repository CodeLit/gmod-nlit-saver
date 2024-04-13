local l = nlitLang
local CWC = CW:Lib('colors')
hook.Add('HUDPaint', 'ENL Dulpicator Progress', function()
  if not CWSaver.InProgress or CWSaver.Abort then return end
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
  if CWSaver.InProgress and LocalPlayer():KeyPressed(IN_RELOAD) then CWSaver.Abort = true end
end)

hook.Add('PreDrawHalos', 'ENL Duplicator Draw', function()
  if not CWSaver:IsPlyHolding(LocalPlayer()) then return end
  if not table.IsEmpty(CWSaver.Ents) then
    local haloEnts = {}
    for ent, bool in pairs(CWSaver.Ents) do
      if bool and IsValid(ent) then
        table.insert(haloEnts, ent)
      else
        CWSaver.Ents[ent] = nil
      end
    end

    halo.Add(haloEnts, Color(51, 255, 51), 1, 1, 15, true, true)
  end

  if not table.IsEmpty(CWSaver.ClientProps) then
    local haloWhiteEnts = {}
    local haloRedEnts = {}
    for _, ent in pairs(CWSaver.ClientProps) do
      if ent:GetNoDraw() then
        table.insert(haloRedEnts, ent)
      else
        table.insert(haloWhiteEnts, ent)
      end
    end

    halo.Add(haloWhiteEnts, CWC:White(), 1, 1, 15, true, true)
    halo.Add(haloRedEnts, CWC:Red(), 1, 1, 15, true, true)
  end
end)

CWSaver:debug('HOOKS LOADED!')