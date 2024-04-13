local l = nlitLang.l
language.Add('Tool.' .. nlitSaver.tool .. '.name', l('Saver'))
language.Add('Tool.' .. nlitSaver.tool .. '.desc', l('Saves groups of items'))
language.Add('Tool.' .. nlitSaver.tool .. '.0', l('Click on any of items to add / remove it from the bunch. Press [R] to unselect all') .. '.')
nlitSaver:debug('LANGS LOADED!')