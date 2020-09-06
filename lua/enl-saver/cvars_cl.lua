local saver = ENL.Saver

saver.previewCvar = CreateClientConVar('enl_saver_preview','0')

cvars.AddChangeCallback(saver.previewCvar:GetName(), function(cName, old, new)
  saver:SetClientProps()
end)