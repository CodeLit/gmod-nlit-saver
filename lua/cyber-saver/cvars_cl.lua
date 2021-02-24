-- [do not obfuscate]

local cvar_name = CWSaver.tool..'_preview'

CWSaver.previewCvar = CreateClientConVar(cvar_name,'0')

cvars.AddChangeCallback(cvar_name, function(cName, old, new)
  CWSaver:SetClientProps()
end)

CWSaver:debug('CVARS LOADED!')