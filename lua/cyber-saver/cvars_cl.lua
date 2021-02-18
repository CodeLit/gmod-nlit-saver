-- [do not obfuscate]

local saver = CW.Saver

saver.previewCvar = CreateClientConVar(CW.Saver.tool..'_preview','0')

cvars.AddChangeCallback(saver.previewCvar:GetName(), function(cName, old, new)
  saver:SetClientProps()
end)

