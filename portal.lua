-- HarrierJack portal MineGateControl portal_mgc

-- TODO ideas
-- create bulb (damaging?deadkly) when turned on, slightly lighter/whiter color (square-2 till 1)
-- test if ring is still complete before opening portal
-- END TODO


-- check if portal ring material exists and fall back to default diamond
if not minetest.registered_nodes[portal_mgc.ring_material] then
	portal_mgc.ring_material = "default:diamondblock"
end



-- helper function to swap coordinates for different portal orientation
-- swaps x and z coordinates and returns the vector
function portal_mgc.swap_coordinates(vec)
	return {x=vec.z, y=vec.y, z=vec.x}
end


-- return facedir from difference in position between dhd and keystone
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
			
			-- make sure facedir is correct for the portal e.g. dhd close to portal gives wrong facedir
			if v.x - pos.x <= 0 then 
				facedir = 1
			else 
				facedir = 3
			end
			
			-- register portal keystone
			portal_mgc.register_portal(player_name, v, facedir, pos)
			
			-- register portal with DHD
			meta:set_string("portal_keystone", minetest.serialize(v))		
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
	
	-- set dhd and keystone enabled
	minetest.get_meta(pos):set_int("enabled", 1)
	--local portal = portal_mgc.find_gate(pos)
	
	minetest.sound_play("gateOpen", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
				
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
	
	-- set disabled keystone and dhd
	minetest.get_meta(pos):set_int("enabled", 0)
	minetest.sound_play("gateClose", {pos = pos, gain = 1.0,loop = false, max_hear_distance = 72,})
			
end


-- dhd digability
portal_can_dig = function(pos,player)
	local player_name = player:get_player_name()
	local meta = core.get_meta(pos)
	if meta:get_string("dont_destroy") == "true" then return end	-- TODO remove or use dont_destroy tag
	local owner=meta:get_string("owner")
	if player_name==owner then return true
	else return false end
end




-- technic function
local function dhd_run(pos, node)
	local meta = minetest.get_meta(pos)	
	local prefix = portal_mgc.power_type
	local dhd_demand = portal_mgc.power_demand
	local ppos = minetest.deserialize(meta:get_string("portal_keystone"))
	if ppos == nil then return end
	
	local dhd_on = meta:get_int("enabled")
	local portal_on = minetest.get_meta(ppos):get_int("enabled")
	local demand = meta:get_int(prefix.."_EU_demand")
	local input = meta:get_int(prefix.."_EU_input")
	
	-- if portal on and input doesnt meet demand -> deactivate
	if portal_on == 1 and input < demand then
		if ppos ~= nil then
			deactivate_portal(ppos, meta:get_string("portal_dir"))
			
		end
	end
	
		
	-- if dhd on and portal of while input meets demand -> activate
	if dhd_on == 1 and portal_on == 0 and input >= demand then
		if ppos ~= nil then
			activate_portal(ppos, meta:get_string("portal_dir"))
		end
		
	end
	
	
	-- if dhd off while portal on -> deactivate
	if dhd_on == 0 and portal_on == 1 then
		if ppos ~= nil then
			deactivate_portal(ppos, meta:get_string("portal_dir"))
		end
	end
	
	
	
	-- set new demand and make sure dhd infotext isn't stuck on "no network" (set inside technic, no direct access afaik)
	if meta:get_int("enabled") == 0 then
		meta:set_int(prefix.."_EU_demand", 0)
		meta:set_string("infotext", "")
	else
		meta:set_int(prefix.."_EU_demand", dhd_demand)
		meta:set_string("infotext", "")
	end
	
end


-- portal node which will be the event horizon (and abm registered block for teleport)
minetest.register_node(portal_mgc.modname .. ":portal_block_inside", {
	description = "Portal Block",
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
	walkable = false,	
		

	pointable = false,
	diggable = false,
		
	groups = { not_in_creative_inventory=1 },
		
})


-- set should be either 0 or 1
function portal_mgc.enable_dhd(pos, set)
	local meta = minetest.get_meta(pos)

	meta:set_int("enabled", set)
	meta:set_int(portal_mgc.power_type.."_EU_demand", (set*portal_mgc.power_demand))
end


minetest.register_node(portal_mgc.modname .. ":dhd", {
	description = "Dial Home Device",
	tiles = {"dhd_1_top.png","dhd_2_bottom.png","dhd_3_side.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,

	groups = {cracky=3, tubedevice=0, technic_machine=1, technic_hv=1, technic_mv=1, technic_lv=1, },
	connect_sides = {"bottom", "front", "back", "left", "right"},		-- connections for technic power

	-- TODO fix sound?
	--sounds = default_stone_sounds, 
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
				
		meta:set_int("enabled", 0)
					
		-- check for available gate
		local gate_pos = find_gate_pos(pos, portal_mgc.dhd_check_radius, placer)
		if not gate_pos then meta:set_string("infotext", "No connection to portal") end		-- TODO perhaps never seen with technic (no network)
		
			
	end,
	on_rightclick = portal_mgc.gateFormspecHandler,
	can_dig = portal_can_dig,
	on_destruct = function(pos)		
			local meta = minetest.get_meta(pos)
			local ppos = minetest.deserialize(meta:get_string("portal_keystone"))
			local player_name = meta:get_string("owner")
			
			-- dont try to unregister when there is no registered portal
			if ppos ~= nil then
				if minetest.get_meta(ppos):get_int("enabled") == 1 then
					-- deactivate portal or undiggable portal blocks remain
					deactivate_portal(ppos, meta:get_string("portal_dir"))
				end
				portal_mgc.unregister_portal(player_name, ppos) 
			end
					
	end,

	-- enable technic hv 
	 technic_run = dhd_run,
			
	mesecons = {effector = {
	action_on = function (pos, node)
			local meta = minetest.get_meta(pos)
			local ppos = minetest.deserialize(meta:get_string("portal_keystone"))

			if meta:get_int("enabled") == 0 and ppos ~= nil then	
				local portal = portal_mgc.find_gate(ppos)
				if portal == nil then return end

				local dest_gate = portal_mgc.find_gate_by_symbol(portal["destination"])
				if dest_gate == nil then return end				
					
					
				portal_mgc.enable_dhd(pos, 1)
			end
		end,

		action_off = function (pos, node)
			portal_mgc.enable_dhd(pos, 0)

		end

	}},	
		
		
	-- enable/disble portal by punching
	on_punch = function(pos) 
		local meta = minetest.get_meta(pos)
		local ppos = minetest.deserialize(meta:get_string("portal_keystone"))
			
						
		if meta:get_int("enabled") == 0 and ppos ~= nil then	
			local portal = portal_mgc.find_gate(ppos)
			if portal == nil then return end
				
			local dest_gate = portal_mgc.find_gate_by_symbol(portal["destination"])
			if dest_gate == nil then return end			
				
			minetest.sound_play("gateSpin", {pos = ppos, gain = 0.5,loop = false, max_hear_distance = 16,})
			portal_mgc.enable_dhd(pos, 1)
			minetest.get_node_timer(pos):start(8)
		end
			
		end,
		
	on_timer = function(pos, elapsed)	
			-- toggle portal on/off
			local meta = minetest.get_meta(pos)						
			local is_on = meta:get_int("enabled")
			
			if is_on == 1 then 
				portal_mgc.enable_dhd(pos, 0)
			else 
				portal_mgc.enable_dhd(pos, 1)
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
			
			-- TODO rearrange code so only if objects are near, vars are set (now they are uselessly 'reset' for each object..)
		for _,object in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
					
				local ppos = minetest.deserialize(meta:get_string("portal_keystone"))
				local owner = minetest.get_meta(ppos):get_string("owner")	
									
				local gate=portal_mgc.find_gate (ppos)
				if gate==nil then print("Gate is not registered!") return end			
				
				local dest_gate = portal_mgc.find_gate_by_symbol(gate["destination"])
				
				if dest_gate == nil then return end
				
				local pos1={}
				pos1.x=dest_gate["pos"].x
				pos1.y=dest_gate["pos"].y
				pos1.z=dest_gate["pos"].z
					
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
					
				-- increase dhd timer by 2 if there was one
				local dpos = minetest.get_meta(ppos):get_string("portal_dhd")	
				dpos = minetest.deserialize(dpos)					
				local timer = minetest.get_node_timer(dpos)
				
				if timer:is_started() then
					timer:start(timer:get_timeout() + portal_mgc.portal_time_extra)
				end

		end
	end
}) 

-- register technic machine (or register abm to simulate the same loop)
if (minetest.get_modpath("technic")) ~= nil then
	technic.register_machine(portal_mgc.power_type, portal_mgc.modname ..":dhd", technic.receiver)
	
else 
	minetest.register_abm({
		nodenames = {portal_mgc.modname .. ":dhd"},
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
				
					-- set values required for technic to zero (not nil)
					portal_mgc.power_demand = 0 
					minetest.get_meta(pos):set_int(portal_mgc.power_type.."_EU_input", 0)
				
					dhd_run(pos,node)
				
				end,
	})
end
