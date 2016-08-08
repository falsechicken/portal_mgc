-- default GUI page
portal_mgc.default_page = "main"

local K_PORTALS = "registered_portals"

-- TODO possibly depcrecated
local function table_empty(tab)
	for key in pairs(tab) do return false end
	return true
end

portal_mgc.save_data = function(table_pointer)
	local data = minetest.serialize( portal_network[table_pointer] )
	local path = minetest.get_worldpath().."/portal_"..table_pointer..".data"
	local file = io.open( path, "w" )
	if( file ) then
		file:write( data )
		file:close()
		return true
	else return nil
	end
end

portal_mgc.restore_data = function(table_pointer)
	local path = minetest.get_worldpath().."/portal_"..table_pointer..".data"
	local file = io.open( path, "r" )
	if( file ) then
		local data = file:read("*all")
		portal_network[table_pointer] = minetest.deserialize( data )
		file:close()
		if table_empty(portal_network[table_pointer]) then os.remove(path) end
	return true
	else return nil
	end
end

-- load portals network data
if portal_mgc.restore_data(K_PORTALS) == nil then
	print ("[portal] Error loading data! Creating new file. " .. K_PORTALS)
	portal_network[K_PORTALS]={}
	portal_mgc.save_data(K_PORTALS)
end



-- register new portal
portal_mgc.register_portal = function(player_name, pos, dir, dhd_pos)
	local address = portal_mgc.create_symbols()
	
	local new_gate ={}
	new_gate["pos"]=pos
	new_gate["type"]="public"
	new_gate["name"]= address.s1 .. address.s2 .. address.s3 .. address.s4
	new_gate["dir"]=dir
	new_gate["owner"]=player_name
	new_gate["address"]= address
	new_gate["destination"] = { s1=0, s2=0, s3=0, s4=0 }
	new_gate["index"] = 1
	new_gate["dhd_pos"] = dhd_pos
	table.insert(portal_network[K_PORTALS],new_gate)
	if portal_mgc.save_data(K_PORTALS)==nil then
		minetest.chat_send_player(player_name, "[portal] Couldnt update network file!")
	end
	
	local infotext = "Portal\nOwned by: "..player_name
	
	portal_mgc.set_portal_meta(pos, dir, infotext, player_name, dhd_pos)
		
end


portal_mgc.unregister_portal = function(player_name,gate_pos)	
	local dir
	for __,gate in ipairs(portal_network[K_PORTALS]) do
		if gate["pos"].x==gate_pos.x and gate["pos"].y==gate_pos.y and gate["pos"].z==gate_pos.z then
			dir = gate["dir"]
			table.remove(portal_network[K_PORTALS], __)
			break
		end
	end
	if portal_mgc.save_data(K_PORTALS)==nil then
		minetest.chat_send_player(player_name, "[portal] Couldnt update network file!")
	end
		
	portal_mgc.set_portal_meta(gate_pos, dir, nil, nil, nil)
	
	
end


-- used in gate_defs/portal.lua for teleport
portal_mgc.find_gate = function(pos)
	for __,gate in ipairs(portal_network[K_PORTALS]) do
		if gate["pos"].x==pos.x and gate["pos"].y==pos.y and gate["pos"].z==pos.z then
			return gate
		end
	end
	return nil
end

portal_mgc.find_gate_by_symbol = function(address)
	for __,gate in ipairs(portal_network[K_PORTALS]) do
		if gate["address"].s1 == address.s1 and gate["address"].s2 == address.s2 and gate["address"].s3 == address.s3 and gate["address"].s4 == address.s4 then
			return gate
		end
	end
	return nil	
end


-- return symbol 
portal_mgc.create_symbols = function()
	
	local tmp = {}
	tmp.s1 = math.random(1,4)
	tmp.s2 = math.random(1,4)
	tmp.s3 = math.random(1,4)
	tmp.s4 = math.random(1,4)
	
	
	-- only 256 combinations possible, prevent endless loop
	if table.getn(portal_network[K_PORTALS]) < 256 then
	
		-- see if address is already taken
		-- TODO properly test...
		for __,gate in pairs(portal_network[K_PORTALS]) do 
			if gate["address"].s1 == tmp.s1 and gate["address"].s2 == tmp.s2 and gate["address"].s3 == tmp.s3 and gate["address"].s4 == tmp.s4 then
				-- duplicate, try again
				tmp = portal_mgc.create_symbols()
			end
		end
		return tmp
	else
		return nil	-- TODO perhaps assign 0 to symbols?
	end
		
end

-- create portal infotext 
portal_mgc.set_portal_meta = function (pos, orientation, infotext, owner, dhd_pos)
	-- set meta for all but keystone ring blocks
	for __,v in pairs(portal_mgc.ring) do
		if tonumber(orientation) == 1 or tonumber(orientation) == 3 then v = portal_mgc.swap_coordinates(v) end
		local vpos = vector.add(pos, v)
		
		local meta = minetest.get_meta(vpos)
		meta:set_string("infotext", infotext)
		meta:set_string("owner", owner)	
	end
	
	-- TODO perhaps add keystone to the ring?
	-- don't forget about the keystone (it's not in the ring)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", infotext)
	meta:set_string("owner", owner)
	meta:set_int("enabled", 0)
	
	if dhd_pos ~= nil then meta:set_string("portal_dhd", minetest.serialize(dhd_pos)) end

end


local function paginize_portals(exclude)
	local amount = 6	-- amount of portals on page 
	local c = 6
	portal_pages = {}

	for __,gate in pairs(portal_network[K_PORTALS]) do
		local i = math.floor(c / amount)
		
		if exclude["pos"].x == gate["pos"].x and exclude["pos"].y == gate["pos"].y and exclude["pos"].z == gate["pos"].z then 
			-- nothing..
		elseif gate["type"] == "public" then		
			if portal_pages[i] == nil then portal_pages[i] = {} end
			table.insert(portal_pages[i], gate)	

			c = c + 1

		end
		
	end
	
end


--show formspec to player
portal_mgc.gateFormspecHandler = function(pos, node, clicker, itemstack)
	local player_name = clicker:get_player_name()
	local meta = minetest.get_meta(pos)
	local owner=meta:get_string("owner")
	if player_name~=owner then return end
	local current_gate=nil


	local gatepos = minetest.deserialize(meta:get_string("portal_keystone"))
	if gatepos == nil then minetest.chat_send_player(player_name, "Not registered to a portal, replace near portal.") return end
	
	for __,gate in ipairs(portal_network[K_PORTALS]) do
		if gate["pos"].x==gatepos.x and gate["pos"].y==gatepos.y and gate["pos"].z==gatepos.z then
			current_gate=gate
		end
	end

	-- TODO delete or do something with it
	for __,gate in ipairs(portal_network[K_PORTALS]) do
		if gate["type"]=="public" then 
		end
	end

	if current_gate==nil then 
		minetest.chat_send_player(player_name, "Gate not registered in network! Please remove it and place once again.")
		return nil
	end

	portal_network["current_gate"]=current_gate

	local formspec=portal_mgc.get_formspec(player_name, "main")
	if formspec ~=nil then minetest.show_formspec(player_name, "portal_dhd", formspec) end
end




-- redo of formspec
portal_mgc.get_formspec = function(player_name, page)
	local current_portal = portal_network["current_gate"]
		
	local owner = current_portal["owner"]
	
	local formspec = "size[9.6,8]"

	formspec = formspec .."background[-0.19,-0.3;10,8.8;ui_form_bg.png]"
	
	-- pressed symbols / destination
	formspec = formspec.."image[.5,0;1,1;symbol"..current_portal["destination"].s1 .. ".png]"
	formspec = formspec.."image[2,0;1,1;symbol"..current_portal["destination"].s2 .. ".png]"
	formspec = formspec.."image[3.5,0;1,1;symbol"..current_portal["destination"].s3 .. ".png]"
	formspec = formspec.."image[5,0;1,1;symbol"..current_portal["destination"].s4 .. ".png]"


	-- actual dialing device	
	formspec = formspec.."image_button_exit[2.50,3;1.5,1.5;activate_portal.png;activate;]"
	formspec = formspec.."image_button[2.75,1.5;1,1;symbol1.png;symbol1;]"
	formspec = formspec.."image_button[4.5,3.25;1,1;symbol2.png;symbol2;]"
	formspec = formspec.."image_button[2.75,5;1,1;symbol3.png;symbol3;]"
	formspec = formspec.."image_button[1,3.25;1,1;symbol4.png;symbol4;]"


	-- current gates info
	if page ~= "edit_name" then
		local adr = current_portal["address"]
		formspec = formspec.."label[1.1,6.5;Address: ".. adr.s1 .. adr.s2 .. adr.s3 .. adr.s4 .."]"
	end

	-- edit gate name if owner		
	if player_name == owner and page == "edit_name" then 
		formspec = formspec.."image_button[.5,6.9;.6,.6;ok_icon.png;save_name;]"
		formspec = formspec.."field[1.3,6.9;5,1;name_box;Edit name:;" .. current_portal["name"].."]"
	else 
		-- normal page
		if player_name == owner then formspec = formspec.."image_button[.5,6.9;.6,.6;pencil_icon.png;edit_name;]" end
		formspec = formspec.."label[1.1,6.9;Name: " .. current_portal["name"].."]"
	end
			
		
	-- edit public/private if owner
	if player_name == owner then formspec = formspec.."image_button[.5,7.5;.6,.6;toggle_icon.png;toggle_type;]" end
	formspec = formspec.."label[1.1,7.5;"..current_portal["type"].."]"	

	-- public portal index page select
	local index = current_portal["index"] 
	if index == nil then index = 1 end
	paginize_portals(current_portal)
	
	formspec = formspec.."image_button[6.3,0;.6,.6;left_icon.png;page_left;]"
	formspec=formspec.."label[7.5,0;".. tostring(index) .. " of " ..tostring(#portal_pages).."]"
	formspec = formspec.."image_button[9,0;.6,.6;right_icon.png;page_right;]"

	
	--local portals = portal_network[K_PORTALS]
	local offset = 0
	local size = 0.6
	local y = 1.0
	
	--if portal_pages[index] == nil then paginize_portals(current_portal) end
	
	-- fix in case remembered index was out of bounds
	--if index > table.getn(portal_pages) then index = table.getn(portal_pages) end
	if portal_pages[index] ~= nil then
		for __,portal in pairs(portal_pages[index]) do
			if portal["pos"] ~= current_portal["pos"] and portal["type"] == "public" then

				-- public portal index 
				formspec = formspec.."label[6.45,"..(0.6+offset)..";"..portal["name"].."]"	
				-- portal symbol address		
				formspec = formspec.."image[6.45,"..(y+offset)..";"..size..","..size..";symbol"..portal["address"].s1 ..".png]"
				formspec = formspec.."image[7.25,"..(y+offset)..";"..size..","..size..";symbol"..portal["address"].s2 ..".png]"
				formspec = formspec.."image[8.05,"..(y+offset)..";"..size..","..size..";symbol"..portal["address"].s3 ..".png]"
				formspec = formspec.."image[8.85,"..(y+offset)..";"..size..","..size..";symbol"..portal["address"].s4 ..".png]"

				offset = offset + 1.2

			end		
		end
	end
	
	return formspec
end


local function portal_dial(symbol)
	local adr = portal_network["current_gate"]["destination"]
	
	if adr.s1 > 0 then
		if adr.s2 > 0 then
			if adr.s3 > 0 then
				if adr.s4 > 0 then
					-- empty and set s1
					adr.s1 = symbol
					adr.s2, adr.s3, adr.s4 = 0, 0, 0
				else adr.s4 = symbol end
			else adr.s3 = symbol end
		else adr.s2 = symbol end		
	else adr.s1 = symbol end
	
	portal_network["current_gate"]["destination"] = adr
	
end





-- redo of formspec
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "portal_dhd" then return false end
	
	local portal = portal_network["current_gate"]
	local player_name = player:get_player_name()
	local formspec
		
	-- toggle private/public
	if fields.toggle_type then
		if portal["type"] == "private" then 
			portal["type"] = "public"
		else portal["type"] = "private" end

		minetest.show_formspec(player_name, "portal_dhd", portal_mgc.get_formspec(player_name, "main"))
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		portal_mgc.save_data(K_PORTALS)
		return
	end
	
	if fields.edit_name then
		formspec = portal_mgc.get_formspec(player_name,"edit_name")
		minetest.show_formspec(player_name, "portal_dhd", formspec)
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		return
	end
		
		
	if fields.save_name then
		portal["name"]=fields.name_box
		formspec= portal_mgc.get_formspec(player_name,"main")
		minetest.show_formspec(player_name, "portal_dhd", formspec)
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
			
		portal_mgc.save_data(K_PORTALS)
		return
	end

	-- index page controls
	local index = portal["index"]
	local amount = #portal_pages
		
	if fields.page_left then
		if index > 1 then	
			portal["index"] = index-1
		end
		minetest.show_formspec(player_name, "portal_dhd", portal_mgc.get_formspec(player_name, "main"))	
		minetest.sound_play("paperflip2", {to_player=player_name, gain = 1.0})
		return
	end
		
	if fields.page_right then	
		if index < amount then	
			portal["index"] = index+1
		end
		minetest.show_formspec(player_name, "portal_dhd", portal_mgc.get_formspec(player_name, "main"))	
		minetest.sound_play("paperflip2", {to_player=player_name, gain = 1.0})
		return
	end
		
	-- activate TODO fix logic probably...
	if fields.activate then 
		local dest = portal_mgc.find_gate_by_symbol(portal["destination"])	
			
		-- if s4 isn't set clear symbols and show formspec again
		if portal["destination"].s4 == 0 or dest == nil then
			portal["destination"] = { s1=0,s2=0,s3=0,s4=0 }
			minetest.show_formspec(player_name, "portal_dhd", portal_mgc.get_formspec(player_name, "main"))
			minetest.sound_play("gateSpin", {pos = portal["pos"], gain = 0.5,loop = false, max_hear_distance = 16,})
			return
		end
		
		portal["destination"].x = dest["pos"].x
		portal["destination"].y = dest["pos"].y
		portal["destination"].z = dest["pos"].z
		
		portal["destination_dir"] = dest["dir"]	
			
		-- activate
		activate_portal(portal["pos"], portal["dir"])
		minetest.get_node_timer(portal["dhd_pos"]):start(8)
			
		return 
	end
	
	-- set symbols
	if fields.symbol1 then portal_dial(1) end
	if fields.symbol2 then portal_dial(2) end
	if fields.symbol3 then portal_dial(3) end
	if fields.symbol4 then portal_dial(4) end
		
	if fields.symbol1 or fields.symbol2 or fields.symbol3 or fields.symbol4 then
		minetest.show_formspec(player_name, "portal_dhd", portal_mgc.get_formspec(player_name, "main"))
			
		-- TODO find dhd dialing sound and play for all?	
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		return
	end
			
		
end)

