local l = CW:Lib('translator')

language.Add('Tool.'..CWSaver.tool..'.name', l('Saver'))
language.Add('Tool.'..CWSaver.tool..'.desc', l('Saves groups of items'))
language.Add('Tool.'..CWSaver.tool..'.0', l('Click on any of items to add / remove it from the bunch. Press [R] to unselect all')..'.')

CWSaver:debug('LANGS LOADED!')