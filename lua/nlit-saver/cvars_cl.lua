local cvar_name = nlitSaver.tool .. '_preview'
nlitSaver.previewCvar = CreateClientConVar(cvar_name, '0')
cvars.AddChangeCallback(cvar_name, function(cName, old, new) nlitSaver:SetClientProps() end)
nlitSaver:debug('CVARS LOADED!')