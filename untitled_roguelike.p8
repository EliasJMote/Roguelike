pico-8 cartridge // http://www.pico-8.com
version 17
__lua__

function gen_objects(r)
	return r
end

function gen_enemies(r)
	return r
end

function gen_doors(g,f)

	-- for each room on the floor
	for r in all(f) do
		
		-- each room has a different type of block
		local blk_num = g.block_spr_table[r.name]

		-- generate doors
		for i=1*16+1,16*16 do
			if((i%16 == 1 or i%16 == 0 or flr(i/16) == 1
				or flr(i/16) == 15)) then
				--r.blocks[i] = blk_num
				--if(r.doors[1]) then

					if(check_room_exists(f,{x=r.x,y=r.y+1})) then
						if(i == 1*16+8 or i == 1*16+9) then
							r.blocks[i] = 0
						end
					end
				--end
				--if(r.doors[2]) then
					if(check_room_exists(f,{x=r.x-1,y=r.y})) then
						if(i == 7*16+1 or i == 8*16+1) then
							r.blocks[i] = 0
						end
					end
				--end
				--if(r.doors[3]) then
					if(check_room_exists(f,{x=r.x+1,y=r.y})) then
						if(i == 7*16+16 or i == 8*16+16) then
							r.blocks[i] = 0
						end
					end
				--end
				--if(r.doors[4]) then
					if(check_room_exists(f,{x=r.x,y=r.y-1})) then
						if(i == 15*16+8 or i == 15*16+9) then
							r.blocks[i] = 0
						end
					end
				--end
			end
		end
	end
	
	return f
end

function gen_location(r)
	return r
end

function create_room(g,f,name)
	
	local r = {}
	r.name = name or "normal"

	-- generate doors
	r.doors = {}
	for i=1,4 do
		local val = true
		--[[if(flr(rnd(2)) == 0) then
			val = true
		end
		add(doors,val)]]
	end

	-- each room has a different type of block
	local blk_num = g.block_spr_table[r.name]

	-- declare the empty block table for the room
	r.blocks = {}

	-- generate walls
	for i=1*16+1,16*16 do
		if((i%16 == 1 or i%16 == 0 or flr(i/16) == 1
			or flr(i/16) == 15)) then
			r.blocks[i] = blk_num
			--if(r.doors[1]) then

				if(i == 1*16+8 or i == 1*16+9) then
					--r.blocks[i] = 0
				end
			--end
			--if(r.doors[2]) then
				if(i == 7*16+1 or i == 8*16+1) then
					--r.blocks[i] = 0
				end
			--end
			--if(r.doors[3]) then
				if(i == 7*16+16 or i == 8*16+16) then
					--r.blocks[i] = 0
				end
			--end
			--if(r.doors[4]) then
				if(i == 15*16+8 or i == 15*16+9) then
					--r.blocks[i] = 0
				end
			--end
		end
	end

	-- generate room specifics
	-- generate sacrifice room spikes
	if(r.name == "sacrifice") then
		r.blocks[8*16+8] = 11
	end

	-- generate the room's location randomly
	-- the central room is always at (0,0)
	if(r.name ~= "central") then
 
		-- rooms that the room can be connected to
		local rooms = {}

		-- for the boss type room
		if(r.name == "boss") then
			for i in all(f) do
				if(i.name == "normal") then
					add(rooms,i)
				end
			end
		else
			rooms = f
		end

		-- create possible room connections from the randomly selected room
		local rm_cns = create_possible_room_connections(rooms[flr(rnd(#rooms))+1], name or "normal")

		-- pick one of the 4 possible connections at random
		local rm_num = flr(rnd(4))+1

		-- if the room doesn't exist yet
		if not check_room_exists(f,rm_cns[rm_num]) then

			-- add the room to the floor
			r.x = rm_cns[rm_num].x
			r.y = rm_cns[rm_num].y
			add(f,r)
		end

	else
		-- add the room to the floor
		r.x = 0
		r.y = 0
		add(f,r)
	end

	-- return the floor
	return f
end

-- check if the given room with particular coordinates exists
function check_room_exists(f,r)
	for v in all(f) do
		if(v.x == r.x and v.y == r.y) then
			return true
		end
	end
	return false
end

function create_possible_room_connections(r,name)
	return {{name=name,x=r.x+1,y=r.y},
			{name=name,x=r.x-1,y=r.y},
			{name=name,x=r.x,y=r.y+1},
			{name=name,x=r.x,y=r.y-1}}
end

function get_room(f,r)
	for k,v in pairs(f) do
		if(v.x == r.x and v.y == r.y) then
			return v
		end
	end
	return {name="void",x=r.x,y=r.y}
end

function get_room_connections(f,r)
	local rm_cns = {}
	add(rm_cns,get_room(f,{x=r.x+1,y=r.y}))
	add(rm_cns,get_room(f,{x=r.x-1,y=r.y}))
	add(rm_cns,get_room(f,{x=r.x,y=r.y+1}))
	add(rm_cns,get_room(f,{x=r.x,y=r.y+1}))
	return rm_cns
end

function count_room_connections(f,r)
	local num_cns = 0
	
	if(get_room(f,{x=r.x+1,y=r.y}).name ~= "void") then num_cns = num_cns + 1 end
	if(get_room(f,{x=r.x-1,y=r.y}).name ~= "void") then num_cns = num_cns + 1 end
	if(get_room(f,{x=r.x,y=r.y+1}).name ~= "void") then num_cns = num_cns + 1 end
	if(get_room(f,{x=r.x,y=r.y-1}).name ~= "void") then num_cns = num_cns + 1 end

	return num_cns
end

-- generate a possible floor
function gen_floor(g)

	local f = {}
	f = create_room(g,f,"central")
	
	-- generate 6 to 9 normal rooms
	local num_normal_rooms = 6 + flr(rnd(3))
	while(count_room_type(f,"normal") < num_normal_rooms) do
		f = create_room(g,f,"normal")
	end

	-- generate a battle room
	while(count_room_type(f,"battle") == 0) do
		f = create_room(g,f,"battle")
	end

	-- 25% chance to generate a sacrifice room
	if(flr(rnd(4)) == 0) then
		while(count_room_type(f,"sacrifice") == 0) do
			f = create_room(g,f,"sacrifice")
		end
	end

	-- generate a secret room
	while(count_room_type(f,"secret") == 0) do
		f = create_room(g,f,"secret")
	end

	-- generate a super secret room
	while(count_room_type(f,"super_secret") == 0) do
		f = create_room(g,f,"super_secret")
	end

	-- chance to generate a sub-boss room
	if(flr(rnd(7)) == 0) then
		while(count_room_type(f,"sub_boss") == 0) do
			f = create_room(g,f,"sub_boss")
		end
	end

	-- generate a boss room
	while(count_room_type(f,"boss") == 0) do
		f = create_room(g,f,"boss")
	end

	--[[
	while(count_room_type(f,"devil") == 0 and count_room_type(f,"angel") == 0) do
		if(flr(rnd(2)) == 0) then
			f = create_room(f,"angel")
		else
			f = create_room(f,"devil")
		end
	end
	]]

	return f
end

function validate_floor(f)

	for r in all(f) do

		-- boss room and super secret room must have only one connection
		if(r.name == "boss" or r.name == "super_secret") then
			if(count_room_connections(f,r) > 1) then
				return false
			end
		end

		-- secret room must have at least two connections
		if(r.name == "secret") then
			if(count_room_connections(f,r) < 2) then
				return false
			end
		end
	end

	return true
end

function get_enemies_from_pool(enemy_pool,enemies,room_x,room_y)
	local e_pool = {}
	for e in all(enemy_pool) do
		if(e.x == room_x and e.y == room_y) then
			e_pool = e.enemies
		end
	end
	return e_pool
end

-- spawn enemy function
function spawn_enemy(enemies,x,y, w, h, name)
	
	local e = {}
	e.x = x or 0
	e.y = y or 0
	e.dx = 0
	e.dy = 0
	e.w = w or 8
	e.h = h or 8
	e.name = name or "default"
	e.spd = 1
	e.spr = 35
	e.is_boss = false
	
	if(e.name == "skeleton") then
		e.spr = 36
		e.is_boss = false
	end

	add(enemies,e)

	return enemies
end

-- refresh game timer, enemies
function refresh_room(g)
	g.timer = 0
	g.blocks = {}
	g.enemies = {}
	g.p1.shots = {}
	for i=1,64*64 do
		add(g.blocks,0)
	end
	local room_exists = false
	for r in all(g.floor) do
		if(r.x == g.world.x and r.y == g.world.y) then
			g.blocks = r.blocks
			g.p1.room.name = r.name
			room_exists = true
			local e_pool = get_enemies_from_pool(g.enemy_pool,g.enemies,g.world.x,g.world.y)
			for e in all(e_pool) do
				g.enemies = spawn_enemy(g.enemies,e.x,e.y)
			end
			break
		end
	end
	if not g.room_exists then
		g.p1.room.name = "void"
	end
	return g
	--spawn_time = flr(rnd(2*30)) + 1*30
end

-- update the room when the player exits the screen
function update_room(g)

	-- go to left room
	if(g.p1.x <= 0 - g.p1.dx) then
		g.world.x -= 1
		g.p1.x = 128 - 2 * g.p1.w
		g = refresh_room(g)
	end

	-- go to right room
	if(g.p1.x >= 128 - g.p1.w - g.p1.dx) then
		g.world.x += 1
		g.p1.x = g.p1.w
		g = refresh_room(g)
	end

	-- go to room above
	if(g.p1.y <= 8 - g.p1.dy) then
		g.world.y += 1
		g.p1.y = 128 - 2 * g.p1.h
		g = refresh_room(g)
	end

	-- go to room below
	if(g.p1.y >= 128 - g.p1.h - g.p1.dy) then
		g.world.y -= 1
		g.p1.y = g.p1.h
		g = refresh_room(g)
	end

	-- update current room
	g.cur_room = g.world.x+g.world.y*g.world.width+1

	return g
end

function count_room_type(f,name)
	local num = 0
	for r in all(f) do
		if(r.name == name) then
			num = num + 1
		end
	end
	return num
end

-- check if a map cell is solid
function solid(blocks,x,y)
	local spr = blocks[flr(x/8)+16*flr(y/8)+1]
	if(spr ~= nil) then
		
		if(fget(spr) == 1) then
			return true
		end
	end
	return false
end

-- check if the area is solid
function solid_area(blocks,x,y,w,h)
	return solid(blocks,x+w,y) or solid(blocks,x+w,y+h) or solid(blocks,x,y) or solid(blocks,x,y+h)
end

-- check if two actors have collided
function act_collision(a1,a2)
	if(a1.x<a2.x+a2.w and a1.x+a1.w>a2.x and a1.y<a2.y+a2.h and a1.y+a1.h>a2.y) return true
	return false
end

function update_shots(blocks,shots)
	for s in all(shots) do

		-- update shots
		if(s.dir == "left") then
			s.x = s.x - s.spd
		elseif(s.dir == "right") then
			s.x = s.x + s.spd
		elseif(s.dir == "up") then
			s.y = s.y - s.spd
		elseif(s.dir == "down") then
			s.y = s.y + s.spd
		end

		if(s.x < -8 or s.x > 128 or s.y < -8 or s.y > 128) then
			del(shots,s)
		end

		if solid_area(blocks,s.x,s.y,s.w,s.h) then
			del(shots,s)
		end
	end
	return shots
end

-- player keyboard commands
function player_controls(is_reading,p1)
	local spd = 1.5

	-- move around
	if(not is_reading) then
		-- horizontal movement
		if(btn(0)) then
			p1.dx = -spd
			p1.xdir = "left"
			p1.lastdir = "left"
		end
		if(btn(1)) then
			p1.dx = spd 
			p1.xdir = "right"
			p1.lastdir = "right"
		end
		if not btn(0) and not btn(1) then
			p1.dx = 0
		end
		
		-- vertical movement
		if(btn(2)) then
			p1.dy = -spd
			p1.ydir = "up"
			p1.spr = 34
			p1.lastdir = "up"
		end
		if(btn(3)) then
			p1.dy = spd
			p1.ydir = "down"
			p1.spr = 33
			p1.lastdir = "down"
		end
		if not btn(2) and not btn(3) then
			p1.dy = 0
		end
	end

	-- shoot
	if(btnp(4)) then
		add(p1.shots,{x=p1.x+3,y=p1.y+3,w=1,h=1,spd=2,dir=p1.lastdir})
	end

	return p1
end

-- move the player, an npc or an enemy
function move_act(blocks, act, is_solid)
	
	if(is_solid) then
		if not solid_area(blocks,act.x+act.dx,act.y,act.w,act.h) then
			act.x += act.dx
		else
			act.dx = 0
		end

		if not solid_area(blocks,act.x,act.y+act.dy,act.w,act.h) then
			act.y += act.dy
		else
			act.dy = 0
		end
	else
		act.x += act.dx
		act.y += act.dy
	end

	return act
end

-- ai for the enemy
function enemy_ai(e,p1)
	if e.x < p1.x - 1 then
		e.dx = e.spd
	elseif e.x > p1.x + 1 then
		e.dx = -e.spd
	else
		e.dx = 0
	end

	if e.y < p1.y - 1 then
		e.dy = e.spd
	elseif e.y > p1.y + 1 then
		e.dy = -e.spd
	else
		e.dy = 0
	end
end

function setup_game(g)

	g.game_state = "game"

	g.block_spr_table = {
		normal=1,
		central=2,
		sacrifice=3,
		secret=4,
		super_secret=5,
		battle=6,
		sub_boss=7,
		boss=8,
	}

	g.map_spr_table = {
		normal=17,
		central=18,
		sacrifice=19,
		secret=20,
		super_secret=21,
		battle=22,
		sub_boss=23,
		boss=24,
		angel=25,
		devil=26,
		error=27,
	}

	-- map is defaulted to close at start of game
	g.is_map_open = false

	-- add map toggle to pause screen
	menuitem(1, "toggle map", function() g.is_map_open = not g.is_map_open end)

	-- set the random seed number
	--srand(0)
			
	-- setup game music and reserve channel 1
	--music(-1)
	--music(0, 0, 1)

	-- initialize the game timer
	g.timer = 0

	-- initialize the player
	g.p1 = {x=64, y=64, dx=0, dy=0, w=7, h=7, xdir="right", ydir="down", lastdir="right"}
	g.p1.room = {name="central"}
	g.p1.cur_health = 6
	g.p1.max_health = 6
	g.p1.spr = 33
	g.p1.shots = {}

	-- initialize enemy table
	g.enemy_pool = {{x=0,y=0,enemies={{x=16,y=16}}}}
	g.enemies = {}

	g.enemy_shots = {}

	-- initialize the starting floor
	g.world = {x=0,y=0,width=3,height=3}

	-- create a floor
	g.floor = gen_floor(g)
	while(validate_floor(g.floor) == false) do
		g.floor = gen_floor(g)
	end

	-- if the floor is good, generate doors for the rooms
	g.floor = gen_doors(g,g.floor)

	-- set up the blocks for the start room (rooms are 16w x 15h)
	g.blocks = {}
	for r in all(g.floor) do
		if(r.x == g.world.x and r.y == g.world.y) then
			g.blocks = r.blocks
		end
	end

	-- initialize the current room value
	g.cur_room = 0

	g = refresh_room(g)

	return g
end

function draw_map(g)
	for r in all(g.floor) do
		spr(g.map_spr_table[r.name],64+r.x*8,64-r.y*8)
	end

	if(g.timer % 30 < 15) then

		color(7)
		rect(64+g.world.x*8,64-g.world.y*8,64+g.world.x*8+7,64-g.world.y*8+7)
		color(0)
	end
end

function _init()

	globals = {game_state="title",timer=0}
	--local g = globals

	-- initialize game state
	--g.game_state = "title"

	--g.timer = 0
end 

function _update()
	local g = globals
	g.timer+=1

	if(g.game_state == "title") then
		if(btnp(4)) then
			g = setup_game(g)
		end

	elseif(g.game_state == "game") then
	
		if not(g.is_map_open) then

			-- player controls
			player_controls(g.is_reading,g.p1)

			-- update player
			g.p1 = move_act(g.blocks,g.p1, true)

			g = update_room(g)

			g.p1.shots = update_shots(g.blocks,g.p1.shots)
		end
	end
end

function _draw()
	local g = globals

	cls()

	if(g.game_state == "title") then
		print("untitled roguelike", 32, 0)
		print("press z to start", 36, 64)
		print("v0.1.1",104,120)

	elseif(g.game_state == "game") then

		-- draw gameplay
		if not(g.is_map_open) then

			-- draw player shots
			for s in all(g.p1.shots) do
				--rectfill(s.x,s.y,s.x+3,s.y+3,7)
				circfill(s.x,s.y,1,7)
			end

			-- draw enemies
			for e in all(g.enemies) do
				spr(e.spr,e.x,e.y)
			end

			-- draw enemy shots
			for e in all(g.enemy_shots) do
				circfill(e.x,e.y,1,7)
			end

			-- draw player
			if(g.p1.xdir == "left") then
				spr(g.p1.spr, g.p1.x, g.p1.y, 1, 1, true)
			else
				spr(g.p1.spr, g.p1.x, g.p1.y)
			end

		 	-- draw blocks
		 	for i=1,(16*16) do
		 		local b = g.blocks[i]
		 		if(b ~= 0) then
		 			spr(b,((i-1)*8)%128, 8*flr((i-1)/16))
		 		end
		 	end

		 	-- draw health bar
		 	for i=1,g.p1.cur_health do
		 		rectfill((i-1)*4,0,(i-1)*4+1,7,8)
		 	end
		 	for i=g.p1.cur_health+1,g.p1.max_health do
		 		rectfill((i-1)*4,0,(i-1)*4+1,7,7)
		 	end

		 	--print(world.x .. "," .. world.y .. " " .. p1.room.name, 0, 0, 7)

		-- draw the map
	 	else
	 		draw_map(g)
		end
	end
end

__gfx__
0000000055555555111111118888888889ab3c1288888888eeeeeeee333333335555555500000000000000000000000000000000000000000000000000000000
000000005566665511cccc118800008889ab3c1299000099ee8888ee33bbbb335500005500000000000000000000000000000000000000000000000000000000
00000000565665651c1cc1c18080080889ab3c12a0a00a0ae8e88e8e3b3bb3b35050050500000000000000000088000000000000000000000000000000000000
00000000566556651cc11cc18008800889ab3c12b00bb00be88ee88e3bb33bb35005500500000000000000000086508000000000000000000000000000000000
00000000566556651cc11cc18008800889ab3c1230033003e88ee88e3bb33bb35005500500000000000000000005656500000000000000000000000000000000
00000000565665651c1cc1c18080080889ab3c12c0c00c0ce8e88e8e3b3bb3b35050050500000000000000000805656500000000000000000000000000000000
000000005566665511cccc118800008889ab3c1211000011ee8888ee33bbbb335500005500000000000000008656656500000000000000000000000000000000
0000000055555555111111118888888889ab3c1222222222eeeeeeee333333335555555500000000000000005656656500000000000000000000000000000000
0000000055555555111111115555555557777755599999557755555559999995577777755aaaaaa5855555580000000000000000000000000000000000000000
000000005000000510000001508800057000077590000995777000059999999977777777a0ffff0a808888080000000000000000000000000000000000000000
0000000050000005100000015086508550007705500099055777000599999999777777775aaaaaa5588888850000000000000000000000000000000000000000
000000005000000510000001500565655007700550099005507770059909909977077077ff0ff0ff880880880000000000000000000000000000000000000000
000000005000000510000001580565655007700550099005500777a59909909977077077ff0ff0ff880880880000000000000000000000000000000000000000
00000000500000051000000186566565500000055000000550007aa59999999977777777ffffffff888888880000000000000000000000000000000000000000
0000000050000005100000015656656550077005500990055000aaaa59099095570770755ffffff5588888850000000000000000000000000000000000000000
000000005555555511111111555555555557755555599555555555aa595995955757757555ffff55558888550000000000000000000000000000000000000000
00000000000888000008880090988800000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888800088888090988880007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008f1f1f008888880098a8a80077070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008fffff00888888009888880077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111100111111009222220007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000f1111f00f1111f009222280070770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc0000cccc0000888800007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c00c0000c00c0000800800007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010101010101010000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
