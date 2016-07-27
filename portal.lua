-- HarrierJack portal MineGateControl test

-- WHY won't this work??
--local c_air = minetest.get_content_id("air")
--local c_portal_material = minetest.get_content_id(portal_mgc.ring_material)


-- helper function to swap coordinates for different portal orientation
-- swaps x and z coordinates and returns the vector
function portal_mgc.swap_coordinates(vec)
	return {x=vec.z, y=vec.y, z=vec.x}
end



-- checks if pos is keystone (the middle of lowest row)
-- returns true when pos is a keystone false otherwise
local function check_for_portal_north(pos, data, area)
	local c_air = minetest.get_content_id("air")
	local c_portal_material = minetest.get_content_id(portal_mgc.ring_material)
	
	-- TODO check if already registered as keystone so no other calc is needed
	
	
	-- check for air if not correct no keystone anyway		
	for __,v in pairs(portal_mgc.inside) do
		local vpos = vector.add(pos, v )
		local node = data[area:index(vpos.x, vpos.y, vpos.z)] 
		
		-- if node is not air return false, otherwise keep going
		if node ~= c_air then return false end		
	end
	
	-- check for ring (portal)
	for __,v in pairs(portal_mgc.ring) do
		local vpos = vector.add(pos, v)
		local node = data[area:index(vpos.x, vpos.y, vpos.z)]
		
		-- if node is carbon(atm)
		if node ~= c_portal_material then return false end
	end
	
	
	return true
end


-- checks if pos is keystone (the middle of lowest row)
-- returns true when pos is a keystone false otherwise
local function check_for_portal_east(pos, data, area)
-- swap x and z positions for translation coords
	
	local c_air = minetest.get_content_id("air")
	local c_portal_material = minetest.get_content_id(portal_mgc.ring_material)
	
	
	-- TODO check if already registered as keystone so no other calc is needed
	
	--minetest.chat_send_all("check north?")
	
	-- check for air if not correct no keystone anyway		
	for __,v in pairs(portal_mgc.inside) do
		local vpos = vector.add(pos, portal_mgc.swap_coordinates(v) )
		local node = data[area:index(vpos.x, vpos.y, vpos.z)] 
		
		-- if node is not air return false, otherwise keep going
		if node ~= c_air then return false end		
	end
	
	-- check for ring (portal)
	for __,v in pairs(portal_mgc.ring) do
		local vpos = vector.add(pos, portal_mgc.swap_coordinates(v))
		local node = data[area:index(vpos.x, vpos.y, vpos.z)]
		
		-- if node is carbon(atm)
		if node ~= c_portal_material then return false end
	end
	
	
	return true
end







-- check for a gate at pos with radius 
local function find_gate_pos(pos, radius, player)	
	local minp = vector.subtract(pos, radius)
	local maxp = vector.add(pos, radius)

	local vm = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local data = vm:get_data()
	
	local player_name = player:get_player_name()
	
	--minetest.chat_send_all("test: " .. minp.x .." pos.x=".. pos.x)

	local poslist = minetest.find_nodes_in_area(minp, maxp, portal_mgc.ring_material)
	
	-- for each pos in poslist check if keystone
	for __,v in pairs(poslist) do
		if check_for_portal_north(v, data, area) then
			local meta = minetest.get_meta(pos)
			-- register portal keystone
			portal_mgc.register_portal(player_name, v, "north")
			
			-- register portal with DHD
			meta:set_string("portal_keystone", minetest.serialize(v))		
			meta:set_string("portal_dir", "north")
						
			minetest.chat_send_all("test: north")
			
			return true
		elseif check_for_portal_east(v, data, area) then
			local meta = minetest.get_meta(pos)
			-- register portal keystone
			portal_mgc.register_portal(player_name, v, "east")
			
			-- register portal with DHD
			meta:set_string("portal_keystone", minetest.serialize(v))		
			meta:set_string("portal_dir", "east")
			
			
			minetest.chat_send_all("test: east")
			
			return true
		end
	end
		
	return false
	
end


-- activate portal by swapping the air nodes with diamond
function activate_portal(pos, orientation)
	local minp = vector.subtract(pos, 5)		-- TODO remove static number 5, though it's big enough for very large portal
	local maxp = vector.add(pos, 5)				-- TODO remove static number 5, though it's big enough for very large portal

	local vm = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local data = vm:get_data()
	
	local c_portal_on = minetest.get_content_id("default:diamondblock")
	
	minetest.chat_send_all("orientation " .. orientation)
	
	-- swap air with custom inside block
	for __,v in pairs(portal_mgc.inside) do
		-- swap coords according direction
		if orientation == "east" then v = portal_mgc.swap_coordinates(v) end
		
		local vpos = vector.add(pos, v )
		-- local node = data[area:index(vpos.x, vpos.y, vpos.z)] 
		
		data[vpos] = c_portal_on
		minetest.set_node(vpos, {name=portal_mgc.modname .. ":portal_block_inside"})
		
		-- set all inside blocks portal coords (tmp fix?)
		local meta = minetest.get_meta(vpos)
		meta:set_string("portal_keystone", minetest.serialize(pos))
		
	end
	
	-- set metadata and info text on ring?
	--for __,v in pairs(portal_mgc.ring) do
		--local vpos = vector.add(pos, v)
		--local node = data[area:index(vpos.x, vpos.y, vpos.z)]
		
		-- if node is carbon(atm)
		-- if node ~= c_portal_material then return false end
	--end
	
	minetest.sound_play("gateOpen", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
	minetest.chat_send_all("activated")
	
	
	-- write changes to map	
	--vm:set_data(data)
	--vm:calc_lighting()
	--vm:update_liquids()
	--vm:write_to_map()
		
		
		
end


-- TODO redo activate/deactivate for efficiency with voxelmanip? (but for now make working concept)
-- deactivate portal by swapping the air nodes with diamond
function deactivate_portal(pos, orientation)
	local minp = vector.subtract(pos, 5)		-- TODO remove static number 5, though it's big enough for very large portal
	local maxp = vector.add(pos, 5)				-- TODO remove static number 5, though it's big enough for very large portal

	local vm = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local data = vm:get_data()
	
	local c_portal_off = minetest.get_content_id("air")
	
	-- swap air with diamond	
	for __,v in pairs(portal_mgc.inside) do
		-- swap coords according direction
		if orientation == "east" then v = portal_mgc.swap_coordinates(v) end
		
		local vpos = vector.add(pos, v )
		-- local node = data[area:index(vpos.x, vpos.y, vpos.z)] 
		
		--data[vpos] = c_portal_off
		--minetest.set_node(vpos, {name="default:dirt"})
		minetest.remove_node(vpos)
	end
	
	minetest.sound_play("gateClose", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
	minetest.chat_send_all("deactivated")
	
	-- set metadata and info text on ring?
	--for __,v in pairs(portal_mgc.ring) do
		--local vpos = vector.add(pos, v)
		--local node = data[area:index(vpos.x, vpos.y, vpos.z)]
		
		-- if node is carbon(atm)
		-- if node ~= c_portal_material then return false end
	--end
	
	
	-- write changes to map	
	--vm:set_data(data)
	--vm:calc_lighting()
	--vm:update_liquids()
	--vm:write_to_map()
		
		
		
end


-- function swap_portal_center(pos, 




portalCanDig = function(pos,player)
	local player_name = player:get_player_name()
	local meta = core.get_meta(pos)
	if meta:get_string("dont_destroy") == "true" then return end	-- TODO remove or use dont_destroy tag
	local owner=meta:get_string("owner")
	if player_name==owner then return true
	else return false end
end


-- portal node which will be the event horizon (and abm registered block for teleport)
minetest.register_node(portal_mgc.modname .. ":portal_block_inside", {
	description = "portal block",
	tiles = {"default_diamond_block.png" },

	walkable = false,
	pointable = false,
	diggable = false,
		
	groups = { not_in_creative_inventory, cracky=5 },
		
})


minetest.register_node(portal_mgc.modname .. ":dhd", {
	description = "Dial Home Device",
	tiles = {"dhd_1_top.png","dhd_2_bottom.png","dhd_3_side.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,

	groups = {cracky=2, tubedevice=0, technic_machine=1, technic_hv=1},
	connect_sides = {"bottom", "front", "back", "left", "right"},		-- connections for technic power

	sounds = default_stone_sounds, 
	drawtype = "nodebox", 
	node_box = {
		type = "fixed", 
		fixed = {
						{-0.250000,-0.500000,-0.250000,0.250000,0.375000,0.250000}, --NodeBox 1
	{-0.312500,0.125000,-0.500000,0.312500,0.250000,0.500000}, --NodeBox 2
	{-0.500000,0.125000,-0.312500,0.500000,0.250000,0.312500}, --NodeBox 3
	{-0.125000,0.375000,-0.125000,0.125000,0.500000,0.125000}, --NodeBox 4
	{-0.312500,0.000000,-0.250000,0.312500,0.125000,0.250000}, --NodeBox 5
	{-0.250000,0.000000,-0.312500,0.250000,0.125000,0.312500}, --NodeBox 6
	{-0.437500,0.125000,-0.437500,0.446777,0.175000,0.435060}, --NodeBox 7

	-- rounded base
	{-0.25,-0.5,-0.5,0.25,-0.45,0.5},
	{-0.5,-0.5,-0.25,0.5,-0.45,0.25},
	{-0.3750,-0.5,-0.3750,0.375,-0.45,0.375},
				
		},
	},
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
					
		-- check for available gate
		local gate_pos = find_gate_pos(pos, portal_mgc.dhd_check_radius, placer)
		if not gate_pos then meta:set_string("infotext", "No connection to portal") end
		
			
	end,
	on_rightclick = portal_mgc.gateFormspecHandler,
	can_dig = portalCanDig,
	on_destruct = function(pos)		
			local meta = minetest.get_meta(pos)
			local ppos = minetest.deserialize(meta:get_string("portal_keystone"))
			local player_name = meta:get_string("owner")
			
			-- dont try to unregister when there is no registered portal
			if ppos ~= nil then	
				-- deactivate portal or undiggable portal blocks remain
				deactivate_portal(ppos, meta:get_string("portal_dir"))
				portal_mgc.unregister_portal(player_name, ppos) 
				
			end
					
	end,

		
	-- after_dig_node = pipeworks.scan_for_tube_objects,
	-- on_receive_fields = harvester_receive_fields,
	-- technic_run = harvester_run,
	
		
	-- old test function
	--on_punch = function(pos) 
		-- toggle on/off
	--	local meta = minetest.get_meta(pos)
	--	if meta:get_int("enabled") == 1 then
	--		meta:set_int("enabled", 0)
	--	else
	--		meta:set_int("enabled", 1)
	--	end
	--	end,
		
		
})


minetest.register_abm({
	nodenames = {portal_mgc.modname .. ":portal_block_inside"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		for _,object in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
			if object:is_player() then 
				local player_name = object:get_player_name()
					
				local ppos = minetest.deserialize(meta:get_string("portal_keystone"))
				local owner = minetest.get_meta(ppos):get_string("owner")	
					
					minetest.chat_send_all("trying to prep teleport.." .. owner)	
					
				local gate=portal_mgc.findGate (ppos)
				if gate==nil then print("Gate is not registered!") return end
				local pos1={}
				pos1.x=gate["destination"].x
				pos1.y=gate["destination"].y
				pos1.z=gate["destination"].z
				local dest_gate=portal_mgc.findGate (pos1)
				if dest_gate==nil then 
					gate["destination"]=nil
					--deactivateGate(pos)
					deactivate_portal(ppos, gate["dir"])
					portal_mgc.save_data(owner)
					return
				end
				if player_name~=owner and gate["type"]=="private" then return end
					
					-- TODO fix direction and position?
					
				local dir1=gate["destination_dir"]
				local dest_angle
				if dir1 == 0 then
					pos1.z = pos1.z-2
					dest_angle = 180
				elseif dir1 == 1 then
					pos1.x = pos1.x-2
					dest_angle = 90
				elseif dir1 == 2 then
					pos1.z=pos1.z+2
					dest_angle = 0
				elseif dir1 == 3 then
					pos1.x = pos1.x+2
					dest_angle = -90
				end
					
				pos1 = vector.add(pos1, {x=0,y=0,z=2})
					
				minetest.chat_send_all("trying to teleport..")	
					
					
				object:moveto(pos1,false)
				--object:set_look_yaw(math.rad(dest_angle))
				core.sound_play("enterEventHorizon", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
			end
		end
	end
}) 



-- technic.register_machine("MV", "autofarmer:harvester", technic.receiver)
