-- HarrierJack portal MineGateControl test

-- TODO ideas
-- create bulb (damaging?deadkly) when turned on, slightly lighter/whiter color (square-2 till 1)
-- fix when sounds are played
-- DONE: make viscous inside blocks (max visc?)
-- test if ring is still complete before opening portal

-- END TODO




-- WHY won't this work??
--local c_air = minetest.get_content_id("air")
--local c_portal_material = minetest.get_content_id(portal_mgc.ring_material)


-- helper function to swap coordinates for different portal orientation
-- swaps x and z coordinates and returns the vector
function portal_mgc.swap_coordinates(vec)
	return {x=vec.z, y=vec.y, z=vec.x}
end


local function get_dir_from_diff(dhd_pos, portal_pos)
	local diff = vector.subtract(dhd_pos, portal_pos)
	local facedir = minetest.dir_to_facedir(diff)
	
	return facedir
end



-- checks if pos is keystone (the middle of lowest row)
-- returns true when pos is a keystone false otherwise
local function check_for_portal_north(pos, data, area)
	local c_air = minetest.get_content_id("air")
	local c_portal_material = minetest.get_content_id(portal_mgc.ring_material)
	
	-- check if already registered as keystone so no other calc is needed
	local meta = minetest.get_meta(pos)
	local is_gate = meta:get_string("infotext")
	--not sure if it's a great way for checking but it works atm
	if is_gate ~= "" then return false end	
		
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
	--local c_portal_inside = minetest.get_content_id(portal_mgc.modname .. ":portal_block_inside")
	
	
	-- check if already registered as keystone so no other calc is needed
	local meta = minetest.get_meta(pos)
	local is_gate = meta:get_string("infotext")
	--not sure if it's a great way for checking but it works atm
	if is_gate ~= "" then return false end	
	
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




-- check for a gate at position of dhd with radius 
local function find_gate_pos(pos, radius, player)	
	local facedir
	local minp = vector.subtract(pos, radius)
	local maxp = vector.add(pos, radius)

	local vm = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local data = vm:get_data()
	
	local player_name = player:get_player_name()
	
	local poslist = minetest.find_nodes_in_area(minp, maxp, portal_mgc.ring_material)
	
	
	-- for each pos in poslist check if keystone
	for __,v in pairs(poslist) do
		if check_for_portal_north(v, data, area) then
			local meta = minetest.get_meta(pos)
			--local facedir = get_dir_from_diff(pos, v)
			
			-- make sure facedir is correct for the portal e.g. dhd close to portal gives wrong facedir
			--if facedir == 1 or facedir == 3 then
				if v.z - pos.z <= 0 then 
					facedir = 0
				else 
					facedir = 2
				end
			--end
			
			
			-- register portal keystone
			portal_mgc.register_portal(player_name, v, facedir, pos)
		
			-- register portal with DHD
			meta:set_string("portal_keystone", minetest.serialize(v))		
			--meta:set_string("portal_dir", "north")
			meta:set_int("portal_dir", facedir)
							
			return true
		elseif check_for_portal_east(v, data, area) then
			local meta = minetest.get_meta(pos)
			--local facedir = get_dir_from_diff(pos, v)
			
			-- make sure facedir is correct for the portal e.g. dhd close to portal gives wrong facedir
			--if facedir == 0 or facedir == 2 then
				if v.x - pos.x <= 0 then 
					facedir = 1
				else 
					facedir = 3
				end
			--end			
			
			-- register portal keystone
			portal_mgc.register_portal(player_name, v, facedir, pos)
			
			-- register portal with DHD
			meta:set_string("portal_keystone", minetest.serialize(v))		
			--meta:set_string("portal_dir", "east")
			meta:set_int("portal_dir", facedir)
				
			return true
		end
	end
		
	return false
	
end


-- activate portal by swapping the air nodes with portal blocks
function activate_portal(pos, orientation)
	-- swap air with custom inside block
	for __,v in pairs(portal_mgc.inside) do
		-- swap coords according direction
		if tonumber(orientation) == 1 or tonumber(orientation) == 3 then 
			v = portal_mgc.swap_coordinates(v)  
		end
		
		local vpos = vector.add(pos, v )
		minetest.set_node(vpos, {name=portal_mgc.modname .. ":portal_block_inside"})
		
		-- set all inside blocks portal coords (tmp fix?)
		local meta = minetest.get_meta(vpos)
		meta:set_string("portal_keystone", minetest.serialize(pos))
		
	end
	
	
	minetest.sound_play("gateOpen", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
	--minetest.chat_send_all("activated")
				
end


-- TODO redo activate/deactivate for efficiency with voxelmanip? (but for now make working concept)
-- deactivate portal by swapping the air nodes with diamond
function deactivate_portal(pos, orientation)
	
	-- swap air with diamond	
	for __,v in pairs(portal_mgc.inside) do
		-- swap coords according direction
		if tonumber(orientation) == 1 or tonumber(orientation) == 3 then v = portal_mgc.swap_coordinates(v) end
		
		local vpos = vector.add(pos, v )
		minetest.remove_node(vpos)
	end
	
	minetest.sound_play("gateClose", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
	--minetest.chat_send_all("deactivated")
			
end



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
	drawtype = "glasslike_framed",
	tiles = {"default_water.png"},
	paramtype = "light",
	sunlight_propagates = true,
	alpha = 100,
	liquid_viscosity = 14,
	liquidtype = "source",
	liquid_alternative_flowing = portal_mgc.modname .. ":portal_block_inside",
	liquid_alternative_source = portal_mgc.modname .. ":portal_block_inside",
	liquid_renewable = false,
	liquid_range = 0,
	--collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	walkable = false,	
		

	pointable = false,
	diggable = false,
		
	groups = { not_in_creative_inventory, cracky=3 },
		
})



minetest.register_node(portal_mgc.modname .. ":dhd", {
	description = "Dial Home Device",
	tiles = {"dhd_1_top.png","dhd_2_bottom.png","dhd_3_side.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,

	groups = {cracky=3, tubedevice=0, technic_machine=1, technic_hv=1},
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

	-- added roundish base
	{-0.25,-0.5,-0.5,0.25,-0.45,0.5},
	{-0.5,-0.5,-0.25,0.5,-0.45,0.25},
	{-0.3750,-0.5,-0.3750,0.375,-0.45,0.375},
				
		},
	},
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		
			-- TODO tmp?
			meta:set_int("portal_active", 0)
					
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

	-- TODO enable technic hv 
	-- technic_run = harvester_run,
	
		
	-- enable/disble portal by punching
	on_punch = function(pos) 
		local meta = minetest.get_meta(pos)
		minetest.get_node_timer(pos):start(2)
			
		end,
		
	on_timer = function(pos, elapsed)	
			-- toggle portal on/off
			local meta = minetest.get_meta(pos)			
			local ppos = minetest.deserialize(meta:get_string("portal_keystone"))
			local is_on = minetest.get_meta(ppos):get_int("portal_active")
			local dir = meta:get_string("portal_dir")
			
			
			if is_on == 1 then 
				deactivate_portal(ppos, dir) 
				minetest.get_meta(ppos):set_int("portal_active", 0)
			else 
				activate_portal(ppos, dir) 
				minetest.get_meta(ppos):set_int("portal_active", 1)
				minetest.get_node_timer(pos):start(portal_mgc.portal_time_open)
			end
			
		end,
		
		
})


minetest.register_abm({
	nodenames = {portal_mgc.modname .. ":portal_block_inside"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
			
			-- TODO rearrange code so only if objects are near vars are set (now they are uselessly 'reset' for each object..
		for _,object in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
			--if object:is_player() or true then 
				--local player_name = object:get_player_name()
					
				local ppos = minetest.deserialize(meta:get_string("portal_keystone"))
				local owner = minetest.get_meta(ppos):get_string("owner")	
									
				local gate=portal_mgc.find_gate (ppos)
				if gate==nil then print("Gate is not registered!") return end
					
					-- TODO check if destination is set
				if gate["destination"] == "" then return end	
					
				local pos1={}
				pos1.x=gate["destination"].x
				pos1.y=gate["destination"].y
				pos1.z=gate["destination"].z
				local dest_gate=portal_mgc.find_gate (pos1)
				if dest_gate==nil then 
					gate["destination"]=nil
					deactivate_portal(ppos, gate["dir"])
					portal_mgc.save_data(owner)
					return
				end
				--if player_name~=owner and gate["type"]=="private" then return end
					
				local dir1=gate["destination_dir"]
				local dest_angle
				if dir1 == 0 then
					pos1.z = pos1.z+2
					dest_angle = 0
				elseif dir1 == 1 then
					pos1.x = pos1.x+2
					dest_angle = -90
				elseif dir1 == 2 then
					pos1.z=pos1.z-2
					dest_angle = 180
				elseif dir1 == 3 then
					pos1.x = pos1.x-2
					dest_angle = 90
				end
					
				-- raise height?
				pos1 = vector.add(pos1, {x=0,y=1,z=0})
							
				-- teleport player
				object:moveto(pos1,false)
				object:set_look_yaw(math.rad(dest_angle))
				core.sound_play("enterEventHorizon", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
					
				-- increase dhd timer by 2
				local dpos = minetest.get_meta(ppos):get_string("portal_dhd")	
				dpos = minetest.deserialize(dpos)					
				local timer = minetest.get_node_timer(dpos)
				timer:start(timer:get_timeout() + portal_mgc.portal_time_extra)
					
					
			--end
		end
	end
}) 



-- technic.register_machine("MV", "autofarmer:harvester", technic.receiver)
