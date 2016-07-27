-- default GUI page
portal_mgc.default_page = "main"
portal_network["players"]={}
portal_mgc.current_page={}

local function table_empty(tab)
	for key in pairs(tab) do return false end
	return true
end

portal_mgc.save_data = function(table_pointer)
	if table_empty(portal_network[table_pointer]) then return end
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
if portal_mgc.restore_data("registered_players") ~= nil then
	for __,tab in ipairs(portal_network["registered_players"]) do
		if portal_mgc.restore_data(tab["player_name"]) == nil  then
			--print ("[portal] Error loading data!")
			portal_network[tab["player_name"]] = {}
		end
	end
else
	print ("[portal] Error loading data! Creating new file.")
	portal_network["registered_players"]={}
	portal_mgc.save_data("registered_players")
end

-- register_on_joinplayer
minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	local registered=nil
	for __,tab in ipairs(portal_network["registered_players"]) do
		if tab["player_name"] ==  player_name then registered = true break end
	end
	if registered == nil then
		local new={}
		new["player_name"]=player_name
		table.insert(portal_network["registered_players"],new)
		portal_network[player_name]={}
		portal_mgc.save_data("registered_players")
		portal_mgc.save_data(player_name)
	end
	portal_network["players"][player_name]={}
	portal_network["players"][player_name]["formspec"]=""
	portal_network["players"][player_name]["current_page"]=portal_mgc.default_page
	portal_network["players"][player_name]["own_gates"]={}
	portal_network["players"][player_name]["own_gates_count"]=0
	portal_network["players"][player_name]["public_gates"]={}
	portal_network["players"][player_name]["public_gates_count"]=0
	portal_network["players"][player_name]["current_index"]=0
	portal_network["players"][player_name]["temp_gate"]={}
end)

--portal_mgc.registerGate = function(player_name,pos,dir)
portal_mgc.register_portal = function(player_name,pos, dir)
	--local player_name = player:get_player_name()
	
	if portal_network[player_name]==nil then
		portal_network[player_name]={}
	end
	local new_gate ={}
	new_gate["pos"]=pos
	new_gate["type"]="private"
	new_gate["description"]=""
	new_gate["dir"]=dir
	new_gate["owner"]=player_name
	table.insert(portal_network[player_name],new_gate)
	if portal_mgc.save_data(player_name)==nil then
		minetest.chat_send_player(player_name, "[portal] Couldnt update network file!")
	end
	
	local infotext = "Portal\nOwned by: "..player_name
	
	portal_mgc.set_portal_meta(pos, dir, infotext, player_name, 0)
	
end


portal_mgc.unregister_portal = function(player_name,gate_pos)	
	for __,gate in ipairs(portal_network[player_name]) do
		if gate["pos"].x==gate_pos.x and gate["pos"].y==gate_pos.y and gate["pos"].z==gate_pos.z then
			table.remove(portal_network[player_name], __)
			break
		end
	end
	if portal_mgc.save_data(player_name)==nil then
		minetest.chat_send_player(player_name, "[portal] Couldnt update network file!")
	end
		
	portal_mgc.set_portal_meta(gate_pos, dir, nil, nil, nil)
	
	
end

-- TODO DELETE, changed to unregister_portal
portal_mgc.unregisterGate = function(player_name,pos)
	for __,gates in ipairs(portal_network[player_name]) do
		if gates["pos"].x==pos.x and gates["pos"].y==pos.y and gates["pos"].z==pos.z then
			table.remove(portal_network[player_name], __)
			break
		end
	end
	if portal_mgc.save_data(player_name)==nil then
		minetest.chat_send_player(player_name, "[portal] Couldnt update network file!")
	end
end


-- TODO DELETE? no, used in gate_defs/portal.lua for teleport
portal_mgc.findGate = function(pos)
	for __,tab in ipairs(portal_network["registered_players"]) do
		local player_name=tab["player_name"]
		if type(portal_network[player_name])=="table" then
			for __,gate in ipairs(portal_network[player_name]) do
				if gate then 
					if gate["pos"].x==pos.x and gate["pos"].y==pos.y and gate["pos"].z==pos.z then
						return gate
					end
				end
			end
		end
	end
	return nil
end



-- create set portal infotext 
portal_mgc.set_portal_meta = function (pos, orientation, infotext, owner, active)
	-- set meta for all but keystone ring blocks
	for __,v in pairs(portal_mgc.ring) do
		if orientation == "east" then v = portal_mgc.swap_coordinates(v) end
		local vpos = vector.add(pos, v)
		
		local meta = minetest.get_meta(vpos)
		meta:set_string("infotext", infotext)
		meta:set_string("owner", owner)	
	end
	
	-- don't forget about the keystone (it's not in the ring)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", infotext)
	meta:set_string("owner", owner)
	meta:set_int("portal_active", active)



end


--show formspec to player
portal_mgc.gateFormspecHandler = function(pos, node, clicker, itemstack)
	local player_name = clicker:get_player_name()
	local meta = minetest.get_meta(pos)
	local owner=meta:get_string("owner")
	if player_name~=owner then return end
	local current_gate=nil
	portal_network["players"][player_name]["own_gates"]={}
	portal_network["players"][player_name]["public_gates"]={}
	local own_gates_count=0
	local public_gates_count=0

	local gatepos = minetest.deserialize(meta:get_string("portal_keystone"))
	if gatepos == nil then minetest.chat_send_player(player_name, "Not registered to a portal, replace near portal.") return end
	
	for __,gate in ipairs(portal_network[player_name]) do
		if gate["pos"].x==gatepos.x and gate["pos"].y==gatepos.y and gate["pos"].z==gatepos.z then
			current_gate=gate
		else
		own_gates_count=own_gates_count+1
		table.insert(portal_network["players"][player_name]["own_gates"],gate)
		end
	end
	portal_network["players"][player_name]["own_gates_count"]=own_gates_count

	-- get all public gates
	for __,tab in ipairs(portal_network["registered_players"]) do
		local temp=tab["player_name"]
		if type(portal_network[temp])=="table" and temp~=player_name then
			for __,gates in ipairs(portal_network[temp]) do
				if gates["type"]=="public" then 
					public_gates_count=public_gates_count+1
					table.insert(portal_network["players"][player_name]["public_gates"],gates)
					end
				end
			end
		end

	print(dump(portal_network["players"][player_name]["public_gates"]))
	if current_gate==nil then 
		minetest.chat_send_player(player_name, "Gate not registered in network! Please remove it and place once again.")
		return nil
	end
	portal_network["players"][player_name]["current_index"]=0
	portal_network["players"][player_name]["temp_gate"]["type"]=current_gate["type"]
	portal_network["players"][player_name]["temp_gate"]["description"]=current_gate["description"]
	portal_network["players"][player_name]["temp_gate"]["pos"]={}
	portal_network["players"][player_name]["temp_gate"]["pos"].x=current_gate["pos"].x
	portal_network["players"][player_name]["temp_gate"]["pos"].y=current_gate["pos"].y
	portal_network["players"][player_name]["temp_gate"]["pos"].z=current_gate["pos"].z
	if current_gate["destination"] then 
		portal_network["players"][player_name]["temp_gate"]["destination_description"]=current_gate["destination_description"]
		portal_network["players"][player_name]["temp_gate"]["destination_dir"]=current_gate["destination_dir"]
		portal_network["players"][player_name]["temp_gate"]["destination"]={}
		portal_network["players"][player_name]["temp_gate"]["destination"].x=current_gate["destination"].x
		portal_network["players"][player_name]["temp_gate"]["destination"].y=current_gate["destination"].y
		portal_network["players"][player_name]["temp_gate"]["destination"].z=current_gate["destination"].z
	else
		portal_network["players"][player_name]["temp_gate"]["destination"]=nil
	end
	portal_network["players"][player_name]["current_gate"]=current_gate
	portal_network["players"][player_name]["dest_type"]="own"
	local formspec=portal_mgc.get_formspec(player_name,"main")
	portal_network["players"][player_name]["formspec"]=formspec
	if formspec ~=nil then minetest.show_formspec(player_name, "portal_main", formspec) end
end

-- get_formspec
portal_mgc.get_formspec = function(player_name,page)
	if player_name==nil then return nil end
	portal_network["players"][player_name]["current_page"]=page
	local temp_gate=portal_network["players"][player_name]["temp_gate"]
	local formspec = "size[14,10]"
	--background
	formspec = formspec .."background[-0.19,-0.2;14.38,10.55;ui_form_bg.png]"
	formspec = formspec.."label[0,0.0;portal DHD]"
	formspec = formspec.."label[0,.5;Position: ("..temp_gate["pos"].x..","..temp_gate["pos"].y..","..temp_gate["pos"].z..")]"
	formspec = formspec.."image_button[3.5,.6;.6,.6;toggle_icon.png;toggle_type;]"
	formspec = formspec.."label[4,.5;Type: "..temp_gate["type"].."]"
	formspec = formspec.."image_button[6.5,.6;.6,.6;pencil_icon.png;edit_desc;]"
	formspec = formspec.."label[0,1.1;Destination: ]"
	if temp_gate["destination"] then 
		formspec = formspec.."label[2.5,1.1;("..temp_gate["destination"].x..","
											  ..temp_gate["destination"].y..","
											  ..temp_gate["destination"].z..") "
											  ..temp_gate["destination_description"].."]"
		formspec = formspec.."image_button[2,1.2;.6,.6;cancel_icon.png;remove_dest;]"
	else
	formspec = formspec.."label[2,1.1;Not connected]"
	end
	formspec = formspec.."label[0,1.7;Aviable destinations:]"
	formspec = formspec.."image_button[3.5,1.8;.6,.6;toggle_icon.png;toggle_dest_type;]"
	formspec = formspec.."label[4,1.7;Filter: "..portal_network["players"][player_name]["dest_type"].."]"

	if page=="main" then
	formspec = formspec.."image_button[6.5,.6;.6,.6;pencil_icon.png;edit_desc;]"
	formspec = formspec.."label[7,.5;Description: "..temp_gate["description"].."]"
	end
	if page=="edit_desc" then
	formspec = formspec.."image_button[6.5,.6;.6,.6;ok_icon.png;save_desc;]"
	formspec = formspec.."field[7.3,.7;5,1;desc_box;Edit gate description:;"..temp_gate["description"].."]"
	end
	
	local list_index=portal_network["players"][player_name]["current_index"]
	local page=math.floor(list_index / 24 + 1)
	local pagemax
	if portal_network["players"][player_name]["dest_type"] == "own" then 
		pagemax = math.floor((portal_network["players"][player_name]["own_gates_count"] / 24) + 1)
		
		--TODO DELETE minetest.chat_send_player(player_name, "owngates " .. portal_network["players"][player_name]["own_gates_count"])
		
		local x,y
		for y=0,7,1 do
		for x=0,2,1 do
			local gate_temp=portal_network["players"][player_name]["own_gates"][list_index+1]
			if gate_temp then
				formspec = formspec.."image_button["..(x*4.5)..","..(2.5+y*.87)..";.6,.6;portal_icon.png;list_button"..list_index..";]"
				formspec = formspec.."label["..(x*4.5+.5)..","..(2.3+y*.87)..";("..gate_temp["pos"].x..","..gate_temp["pos"].y..","..gate_temp["pos"].z..") "..gate_temp["type"].."]"
				formspec = formspec.."label["..(x*4.5+.5)..","..(2.7+y*.87)..";"..gate_temp["description"].."]"
			end
			list_index=list_index+1
		end
		end
	else
		pagemax = math.floor((portal_network["players"][player_name]["public_gates_count"] / 24) + 1)
		local x,y
		for y=0,7,1 do
		for x=0,2,1 do
			local gate_temp=portal_network["players"][player_name]["public_gates"][list_index+1]
			if gate_temp then
				formspec = formspec.."image_button["..(x*4.5)..","..(2.5+y*.87)..";.6,.6;portal_icon.png;list_button"..list_index..";]"
				formspec = formspec.."label["..(x*4.5+.5)..","..(2.3+y*.87)..";("..gate_temp["pos"].x..","..gate_temp["pos"].y..","..gate_temp["pos"].z..") "..gate_temp["owner"].."]"
				formspec = formspec.."label["..(x*4.5+.5)..","..(2.7+y*.87)..";"..gate_temp["description"].."]"
			end
			list_index=list_index+1
		end
		end
	end
	formspec=formspec.."label[7.5,1.7;Page: "..page.." of "..pagemax.."]"
	formspec = formspec.."image_button[6.5,1.8;.6,.6;left_icon.png;page_left;]"
	formspec = formspec.."image_button[6.9,1.8;.6,.6;right_icon.png;page_right;]"
	formspec = formspec.."image_button_exit[6.1,9.3;.8,.8;ok_icon.png;save_changes;]"
	formspec = formspec.."image_button_exit[7.1,9.3;.8,.8;cancel_icon.png;discard_changes;]"
	return formspec
end

-- register_on_player_receive_fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formname == "portal_main" then return "" end
	local player_name = player:get_player_name()
	local temp_gate=portal_network["players"][player_name]["temp_gate"]
	local current_gate=portal_network["players"][player_name]["current_gate"]
	local formspec

	if fields.toggle_type then
		if temp_gate["type"] == "private" then 
			temp_gate["type"] = "public"
		else temp_gate["type"] = "private" end
		portal_network["players"][player_name]["current_index"]=0
		formspec= portal_mgc.get_formspec(player_name,"main")
		portal_network["players"][player_name]["formspec"] = formspec
		minetest.show_formspec(player_name, "portal_main", formspec)
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		return
	end
	if fields.toggle_dest_type then
		if portal_network["players"][player_name]["dest_type"] == "own" then 
			portal_network["players"][player_name]["dest_type"] = "all public"
		else portal_network["players"][player_name]["dest_type"] = "own" end
		portal_network["players"][player_name]["current_index"] = 0
		formspec = portal_mgc.get_formspec(player_name,"main")
		portal_network["players"][player_name]["formspec"] = formspec
		minetest.show_formspec(player_name, "portal_main", formspec)
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		return
	end
	if fields.edit_desc then
		formspec= portal_mgc.get_formspec(player_name,"edit_desc")
		portal_network["players"][player_name]["formspec"]=formspec
		minetest.show_formspec(player_name, "portal_main", formspec)
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		return
	end

	if fields.save_desc then
		temp_gate["description"]=fields.desc_box
		formspec= portal_mgc.get_formspec(player_name,"main")
		portal_network["players"][player_name]["formspec"]=formspec
		minetest.show_formspec(player_name, "portal_main", formspec)
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		return
	end
	
	-- page controls
	local start=math.floor(portal_network["players"][player_name]["current_index"]/24 +1 )
	local start_i=start
	local pagemax = math.floor(((portal_network["players"][player_name]["own_gates_count"]-1) / 24) + 1)
	
	if fields.page_left then
		minetest.sound_play("paperflip2", {to_player=player_name, gain = 1.0})
		start_i = start_i - 1
		if start_i < 1 then	start_i = 1	end
		if not (start_i	== start) then
			portal_network["players"][player_name]["current_index"] = (start_i-1)*24
			formspec = portal_mgc.get_formspec(player_name,"main")
			portal_network["players"][player_name]["formspec"] = formspec
			minetest.show_formspec(player_name, "portal_main", formspec)
		end
	end
	if fields.page_right then
		minetest.sound_play("paperflip2", {to_player=player_name, gain = 1.0})
		start_i = start_i + 1 
		if start_i > pagemax then start_i =  pagemax end
		if not (start_i	== start) then
			portal_network["players"][player_name]["current_index"] = (start_i-1)*24
			formspec = portal_mgc.get_formspec(player_name,"main")
			portal_network["players"][player_name]["formspec"] = formspec
			minetest.show_formspec(player_name, "portal_main", formspec)
		end
	end

	if fields.remove_dest then
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		temp_gate["destination"]=nil
		temp_gate["destination_description"]=nil
		formspec = portal_mgc.get_formspec(player_name,"main")
		portal_network["players"][player_name]["formspec"] = formspec
		minetest.show_formspec(player_name, "portal_main", formspec)
	end

	if fields.save_changes then
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
		local meta = minetest.get_meta(temp_gate["pos"])
		local infotext=""
		current_gate["type"]=temp_gate["type"]
		current_gate["description"]=temp_gate["description"]
		current_gate["pos"]={}
		current_gate["pos"].x=temp_gate["pos"].x
		current_gate["pos"].y=temp_gate["pos"].y
		current_gate["pos"].z=temp_gate["pos"].z
		current_gate["dest"]=temp_gate["dest"]
		if temp_gate["destination"] then 
			current_gate["destination"]={}
			current_gate["destination"].x=temp_gate["destination"].x
			current_gate["destination"].y=temp_gate["destination"].y
			current_gate["destination"].z=temp_gate["destination"].z
			current_gate["destination_description"]=temp_gate["destination_description"]
			current_gate["destination_dir"]=temp_gate["destination_dir"]
		else
			current_gate["destination"]=nil
		end
		if current_gate["destination"] then 
			-- TODO FIX activation
			--activateGate (current_gate["pos"])
			activate_portal(current_gate["pos"], current_gate["dir"])
		else
				-- TODO FIX deactivation
			--deactivateGate (current_gate["pos"])
			deactivate_portal(current_gate["pos"], current_gate["dir"])
		end
		if current_gate["type"]=="private" then infotext="Private"	else infotext="Public" end
		infotext=infotext.." Gate: "..current_gate["description"].."\n"
		infotext=infotext.."Owned by "..player_name.."\n"
		if current_gate["destination"] then 
			infotext=infotext.."Destination: ("..current_gate["destination"].x..","..current_gate["destination"].y..","..current_gate["destination"].z..") "
			infotext=infotext..current_gate["destination_description"]
		end
		portal_mgc.set_portal_meta(current_gate["pos"], current_gate["dir"], infotext, player_name, 0)
		-- meta:set_string("infotext",infotext)
		if portal_mgc.save_data(player_name)==nil then
			minetest.chat_send_player(player_name, "[portal] Couldnt update network file!")
		end
	end

	if fields.discard_changes then
		minetest.sound_play("click", {to_player=player_name, gain = 0.5})
	end

	local list_index=portal_network["players"][player_name]["current_index"]
	local i
	for i=0,23,1 do
	local button="list_button"..i+list_index
	if fields[button] then 
		minetest.sound_play("click", {to_player=player_name, gain = 1.0})
		local gate=portal_network["players"][player_name]["temp_gate"]
		local dest_gate
		if portal_network["players"][player_name]["dest_type"] == "own" then
			dest_gate=portal_network["players"][player_name]["own_gates"][list_index+i+1]
		else
			dest_gate=portal_network["players"][player_name]["public_gates"][list_index+i+1]
		end
		gate["destination"]={}
		gate["destination"].x=dest_gate["pos"].x
		gate["destination"].y=dest_gate["pos"].y
		gate["destination"].z=dest_gate["pos"].z
		gate["destination_description"]=dest_gate["description"]
		gate["destination_dir"]=dest_gate["dir"]
		formspec = portal_mgc.get_formspec(player_name,"main")
		portal_network["players"][player_name]["formspec"] = formspec
		minetest.show_formspec(player_name, "portal_main", formspec)
	end
	end
end)