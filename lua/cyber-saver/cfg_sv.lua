local name = 'Saver'

CWCfg:AddAddon(name)
CWCfg:Set(name,'Max. Items Spawn Distance', 500,'num')
CWCfg:Set(name,'Delay Between Single Propspawn',0.5,'num')
CWCfg:Set(name,'Save Cooldown',5,'num')
CWCfg:Set(name,'Classes To Save',{'prop_physics'},'table')
CWCfg:Set(name,'Create Indestructible Items',true,'bool')
-- NCfg:Set(name,'Текстовое поле 1','300','text')

util.AddNetworkString(CWSaver.netstr)

CWSaver:debug('CFG LOADED!')