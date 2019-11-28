pico-8 cartridge // http://www.pico-8.com
version 17
__lua__

function enemy_formations(g)
end

--function gen_objects(r)
    --return r
--end

function create_possible_room_connections(r,name)
    return {{name=name,x=r.x+1,y=r.y},
            {name=name,x=r.x-1,y=r.y},
            {name=name,x=r.x,y=r.y+1},
            {name=name,x=r.x,y=r.y-1}}
end

function gen_enemies(r)
    return r
end

-- create the doors for each room
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

function gen_enemies_in_room(name,x,y)
    --local enemies = {}
    local enemies = {{x=8*flr(rnd(8))+32,y=8*flr(rnd(8))+32,w=8,h=8,name="demon"}}

    return {x=x,y=y,enemies=enemies}
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

            --add(g.enemy_pool,gen_enemies_in_room(r.name,r.x,r.y))
        end

    else
        -- add the room to the floor
        r.x = 0
        r.y = 0
        add(f,r)
    end

    -- add enemies to room
    if(r.name == "normal") add(g.enemy_pool,gen_enemies_in_room(r.name,r.x,r.y))

    -- generate the enemies
    --g.enemy_pool = {{x=0,y=0,enemies={{x=16,y=16}}}}
    

    -- return the floor
    return g.enemy_pool,f
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

-- get the room given specific coordinates
function get_room(f,r)
    for k,v in pairs(f) do
        if(v.x == r.x and v.y == r.y) then
            return v
        end
    end
    return {name="void",x=r.x,y=r.y}
end

-- create a table
function get_room_connections(f,r)
    local rm_cns = {}
    add(rm_cns,get_room(f,{x=r.x+1,y=r.y}))
    add(rm_cns,get_room(f,{x=r.x-1,y=r.y}))
    add(rm_cns,get_room(f,{x=r.x,y=r.y+1}))
    add(rm_cns,get_room(f,{x=r.x,y=r.y+1}))
    return rm_cns
end

-- count the number of rooms that exist and that are connected to the current one
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
    g.enemy_pool,f = create_room(g,f,"central")
    
    -- generate 6 to 9 normal rooms
    local num_normal_rooms = 6 + flr(rnd(3))
    while(count_room_type(f,"normal") < num_normal_rooms) do
        g.enemy_pool,f = create_room(g,f,"normal")
    end

    -- generate a battle room
    while(count_room_type(f,"battle") == 0) do
        g.enemy_pool,f = create_room(g,f,"battle")
    end

    -- 25% chance to generate a sacrifice room
    if(flr(rnd(4)) == 0) then
        while(count_room_type(f,"sacrifice") == 0) do
            g.enemy_pool,f = create_room(g,f,"sacrifice")
        end
    end

    -- generate a secret room
    while(count_room_type(f,"secret") == 0) do
        g.enemy_pool,f = create_room(g,f,"secret")
    end

    -- generate a super secret room
    while(count_room_type(f,"super_secret") == 0) do
        g.enemy_pool,f = create_room(g,f,"super_secret")
    end

    -- chance to generate a sub-boss room
    if(flr(rnd(7)) == 0) then
        while(count_room_type(f,"sub_boss") == 0) do
            g.enemy_pool,f = create_room(g,f,"sub_boss")
        end
    end

    -- generate a boss room
    while(count_room_type(f,"boss") == 0) do
        g.enemy_pool,f = create_room(g,f,"boss")
    end

    
    --[[while(count_room_type(f,"devil") == 0 and count_room_type(f,"angel") == 0) do
        if(flr(rnd(2)) == 0) then
            f = create_room(g,f,"angel")
        else
            f = create_room(g,f,"devil")
        end
    end]]
    

    return g.enemy_pool,f
end

-- validates if a floor meets the necessary requirements
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

-- count how many rooms exist of a certain type name
function count_room_type(f,name)
    local num = 0
    for r in all(f) do
        if(r.name == name) then
            num = num + 1
        end
    end
    return num
end







--#include level_gen.p8

--------------------------------------------------------------------------------------------------------







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

-- update player shots
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

        if (s.x < 0 or s.x > 128 + 8 or s.y < 8 or s.y > 128 + 8) then
            del(shots,s)
        end

        if (solid_area(blocks,s.x,s.y,s.w,s.h) and not s.spectral) then
            del(shots,s)
        end
    end
    return shots
end

-- player keyboard commands
function player_controls(is_reading,p1,timer)
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
            p1.spr = 33 + 16
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
        add(p1.shots,{x=p1.x+3,y=p1.y+3,w=1,h=1,spd=2,dir=p1.lastdir,faction="player",spectral=true})
    end

    return p1
end

-- ai for the enemy
function enemy_ai(e,p1,enemy_shots)
    -- follow pattern
    if(e.timer < 30) then
        e.dx = 0
        e.dy = 0

    elseif(e.timer >= 30) then
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

    if(e.timer >= 60) then
        add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,dir="up",spectral=true,type="fireball"})
        add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,dir="down",spectral=true,type="fireball"})
        add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,dir="left",spectral=true,type="fireball"})
        add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,dir="right",spectral=true,type="fireball"})
        e.timer = 0
    end

    e.timer = e.timer + 1

    return e,enemy_shots
end

--#include game_physics.p8







---------------------------------------------------------------------------------------------------------------------------------------






-- get a list of enemies in a particular room in the pool
function get_enemies_from_pool(enemy_pool,room_x,room_y)
	-- check all the rooms in the enemy pool
	for r in all(enemy_pool) do

		-- if we find the room we are looking for, get the list of enemies in it
		if(r.x == room_x and r.y == room_y) then
			return r.enemies
		end
	end

	-- if there is no entry in the enemy pool table, return an empty list
	return {}
end

-- delete a particular enemy from the pool based on a certain room and enemy name
function remove_enemy_from_pool(enemy_pool,enemy,room_x,room_y)
	-- for each room in the enemy pool
	for r in all(enemy_pool) do

		-- if the room in the pool is the one we want
		if(r.x == room_x and r.y == room_y) then

			-- search the table of enemies in the room
			for e in all(r.enemies) do

				-- if we found the name of the enemy that we want, delete it
				if(enemy.name == e.name) then
					del(r.enemies,e)
				end
			end
		end
	end
	return enemy_pool
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
	e.spd = 0.5
	e.spr = 35
	e.is_boss = false
	e.timer = 0
	
	if(e.name == "skeleton") then
		e.spr = 36
		e.is_boss = false
	end

	add(enemies,e)

	return enemies
end

-- refresh game timer, enemies
function refresh_room(g)

	-- reset the timer, room blocks, room enemies, and all shots
	g.timer = 0
	g.blocks = {}
	g.enemies = {}
	g.p1.shots = {}
	g.enemy_shots = {}
	for i=1,64*64 do
		add(g.blocks,0)
	end

	-- we don't know if the new room exists yet
	local room_exists = false
	for r in all(g.floor) do
		if(r.x == g.world.x and r.y == g.world.y) then
			g.blocks = r.blocks
			g.p1.room.name = r.name
			room_exists = true
			local e_pool = get_enemies_from_pool(g.enemy_pool,g.world.x,g.world.y)
			for e in all(e_pool) do
				g.enemies = spawn_enemy(g.enemies,e.x,e.y,e.w,e.h,e.name)
			end

			local has_been_in_room = false
			for e in all(g.map_explored) do
				if(e.x == g.world.x and e.y == g.world.y) then
					has_been_in_room = true
					break
				end
			end
			if not has_been_in_room then
				add(g.map_explored,{x=g.world.x,y=g.world.y})
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

-------------------------------------------- particle system --------------------------------------------

function create_death_particles(particles,x,y)
	for i=1,8 do
		add(particles,{x=x,y=y,dx=(rnd(4)-2),dy=(rnd(4)-2),life_timer=5})
	end
	return particles
end

function update_particles(particles)
	for p in all(particles) do
		p.life_timer -= 1
		if(p.life_timer <= 0) then
			del(particles,p)
		end
		p.x += p.dx
		p.y += p.dy
	end
	return particles
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

	-- initialize the particle system
	g.particles = {}

	-- map is defaulted to close at start of game
	g.is_map_open = false

	-- add map toggle to pause screen
	menuitem(1, "toggle map", function() g.is_map_open = not g.is_map_open end)

	g.map_explored = {{x=0,y=0}}

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
	g.p1.status = "normal"
	--g.p1.status = "stone"

	-- initialize the starting floor
	g.world = {x=0,y=0,width=3,height=3}

	g.enemy_pool = {}

	-- create a floor
	g.enemy_pool,g.floor = gen_floor(g)
	
	while(validate_floor(g.floor) == false) do
		g.enemy_pool = {}
		g.enemy_pool,g.floor = gen_floor(g)
	end
	--printh(#g.enemy_pool)
	-- if the floor is good, generate doors for the rooms
	g.floor = gen_doors(g,g.floor)

	-- set up the blocks for the start room (rooms are 16w x 15h)
	g.blocks = {}
	for r in all(g.floor) do
		if(r.x == g.world.x and r.y == g.world.y) then
			g.blocks = r.blocks
		end
	end

	-- initialize enemy table}
	--g.enemy_pool = {{x=0,y=0,enemies={{x=16,y=16}}}
	g.enemies = {}
	g.enemy_shots = {}

	-- initialize the current room value
	g.cur_room = 0

	g = refresh_room(g)

	return g
end

function draw_map(g)
	for r in all(g.floor) do
		for e in all(g.map_explored) do
			if(e.x == r.x and e.y == r.y) then
				spr(g.map_spr_table[r.name],64+r.x*8,64-r.y*8)
				break
			end
		end
	end

	if(g.timer % 30 < 15) then

		color(7)
		rect(64+g.world.x*8,64-g.world.y*8,64+g.world.x*8+7,64-g.world.y*8+7)
		color(0)
	end
end

function _init()

	-- initialize the global variable that holds game state data
	globals = {game_state="title",timer=0}
end 

function _update()
	local g = globals
	g.timer+=1

	-- title menu
	if(g.game_state == "title") then
		if(btnp(4)) then
			g = setup_game(g)
		end

	-- gameplay
	elseif(g.game_state == "game") then
	
		if not(g.is_map_open) then

			-- player controls
			player_controls(g.is_reading,g.p1,g.timer)

			-- update player
			g.p1 = move_act(g.blocks,g.p1, true)

			-- update the enemies
			for e in all(g.enemies) do
				e,g.enemy_shots = enemy_ai(e,g.p1,g.enemy_shots)
				e = move_act(g.blocks, e, true)

				for s in all(g.p1.shots) do
					if(s.faction == "player") then
            			if(act_collision(s,e)) then
            				--printh(e.name)
            				g.enemy_pool = remove_enemy_from_pool(g.enemy_pool,e,g.world.x,g.world.y)
            				del(g.enemies,e)
            				g.particles = create_death_particles(g.particles,e.x,e.y)
            				if(s.pierce == nil or s.pierce == false) then
            					del(g.p1.shots,s)
            				end
            			end
            		end
            	end
			end

			-- update the current room
			g = update_room(g)

			-- update the player's shots
			g.p1.shots = update_shots(g.blocks,g.p1.shots)

			-- update enemy shots
			g.enemy_shots = update_shots(g.blocks,g.enemy_shots)

			-- update the particle system
			g.particles = update_particles(g.particles)
		end
	end
end

function _draw()
	local g = globals

	-- clear the screen with black
	cls()

	if(g.game_state == "title") then
		print("untitled roguelike", 32, 0)
		print("press z to start", 36, 64)
		print("v0.1.2",104,120)

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
				spr(e.spr+flr(g.timer/10)%2,e.x,e.y)
			end

			-- draw enemy shots
			for e in all(g.enemy_shots) do
				if(e.type == "crescent") then
					spr(52,e.x,e.y)
				elseif(e.type == "fireball") then
					spr(51,e.x,e.y)
				else
					circfill(e.x,e.y,1,7)
				end
			end
			--printh(#g.enemy_pool)
			-- draw player
			if(g.p1.status == "stone") then
				pal(1,5)
				pal(8,5)
				pal(12,6)
				pal(15,7)
			end

			if(g.p1.xdir == "left") then
				spr(g.p1.spr+flr(g.timer/10)%2, g.p1.x, g.p1.y, 1, 1, true)
			else
				spr(g.p1.spr+flr(g.timer/10)%2, g.p1.x, g.p1.y)
			end

			pal()

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

		 	-- draw particles
		 	for p in all(g.particles) do
		 		circfill(p.x,p.y,0.5,8)
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
00000000000888000008880090988800000888000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888800088888090988880909888800077777000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008f1f1f008f1f1f0098a8a80909a8a800770707000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008fffff008fffff009888880098888800777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111100111111009222220092222200077770000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000f1111f00f1111f009222280092222800707707000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc0000cccc0000888800098888000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c0000000000c0000800000000008000070070000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000008880000088800008888000c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888800088888008999980700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800888888089999998c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800888888089977998011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111100111111089977998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000f1111f00f1111f089999998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc0000cccc0008999980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000c0000c0000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010101010101010000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
