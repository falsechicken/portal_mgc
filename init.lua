-- create some basic global vars
portal_network = {}
portal_pages = {}
portal_mgc = {}
portal_mgc.modname = minetest.get_current_modname()
portal_mgc.modpath = minetest.get_modpath(portal_mgc.modname)



-- load default and adjustable settings
dofile(portal_mgc.modpath .. "/default_settings.txt")

-- load portal files
dofile(portal_mgc.modpath .. "/portal_gui.lua")
dofile(portal_mgc.modpath .. "/portal.lua")

-- load craft recipes
-- dofile(portal_mgc.modpath .. "/crafts.lua")

print("MGC loaded")
