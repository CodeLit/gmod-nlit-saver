local name = 'Saver'

NCfg:AddAddon(name)
NCfg:Set(name,'Max. Items Spawn Distance', 500,'num')
NCfg:Set(name,'Delay Between Single Propspawn',0.5,'num')
NCfg:Set(name,'Save Cooldown',5,'num')
NCfg:Set(name,'Classes To Save',{'prop_physics'},'table')
NCfg:Set(name,'Create Indestructible Items',true,'bool')
-- NCfg:Set(name,'Текстовое поле 1','300','text')

util.AddNetworkString(CW.Saver.netstr)