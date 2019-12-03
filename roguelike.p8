pico-8 cartridge // http://www.pico-8.com
version 17
__lua__

-- create a new event. this function should be accessible to each function. the global event creator will help isolate functions from each other.
function create_event(event)
    local g = globals
    add(g.events,event)
end

function _init()

	-- initialize the global variable that holds game state data
	globals = {game_state="title",timer=0,events={}}

    local g = globals

    -- create helper functions accessible from the global state

    ----------------------------------------------- event system ----------------------------------------------

    g.update_events = function(g)

        -- make sure the event queue exists before trying to access it!
        if(g.events ~= nil) then

            while(#g.events > 0) do

                local event = g.events[1]

                -- take an action based on the event's name
                if event.name == "button press" then
                    -- title menu
                    if(g.game_state == "title") then
                        if event.i == 4 then
                            g.game_state = "how_to_play"
                            sfx(2)
                        end

                    -- how to play
                    elseif(g.game_state == "how_to_play") then
                        if event.i == 4 then
                            g = g.setup_game(g)
                            sfx(2)
                        end
                        
                    end
                end

                -- game events
                if g.game_state == "game" then
                    if event.name == "move actor" then
                        if(event.player.num == 1) then
                            g.p1 = g.move_act(g.blocks, event.player, true, true)
                            g = g.update_room(g)
                        end
                    elseif event.name == "stop moving horizontally" then
                        if(event.player.num == 1) then
                            g.p1 = g.move_act(g.blocks, event.player, true, true)
                        end
                    elseif event.name == "stop moving vertically" then
                        if(event.player.num == 1) then
                            g.p1 = g.move_act(g.blocks,event.player, true, true)
                        end
                    elseif event.name == "shoot" then
                    elseif event.name == "take damage" then
                    elseif event.name == "get health" then
                    elseif event.name == "button held" then
                        g.player_controls(g.p1,event.i)
                    elseif event.name == "activate polling" then
                        g.p1.polling = true
                    elseif event.name == "deactivate polling" then
                        g.p1.polling = false
                    elseif event.name == "go to next floor" then
                        g = g.go_to_next_floor(g)
                    end
                end

                -- remove the event from the queue once it's finished
                del(g.events,event)
            end
        end

        -- return the global state when we're done
        return g
    end

    --------------------------------------------- event listeners ---------------------------------------------

    g.button_listener = function()
        for p=0,0 do
            for i=0,5 do
                if btnp(i,p) then
                    create_event({name="button press",i=i,p=p})
                end
            end
            for i=0,5 do
                if btn(i,p) then
                    create_event({name="button held",i=i,p=p})
                    break
                end
            end
        end
    end

    -------------------------------------------- new game creation --------------------------------------------
    g.setup_game = function(g)

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

        g.rainbow_colors = {8,9,10,11,3,12,1,2}

        -- initialize the object table
        g.objects = {}

        -- initialize the particle system
        g.particles = {}

        -- map is defaulted to close at start of game
        --g.is_map_open = false

        -- add map toggle to pause screen
        local function map_toggle()
            if globals.game_state ~= "map" then 
                globals.game_state = "map" 
            else 
                globals.game_state = "game"
            end
        end
        menuitem(1, "toggle map", map_toggle)

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
        g.p1.can_shoot = true
        g.p1.shot_timer = 0
        g.p1.money = 0
        g.p1.bombs = 0
        g.p1.status = "normal"

        -- initialize the starting floor
        g.world = {x=0,y=0,level=0}

        g.enemy_pool = {}

        -- create a floor
        g.enemy_pool,g.floor = g.gen_floor(g)
        
        while(g.validate_floor(g.floor) == false) do
            g.enemy_pool = {}
            g.enemy_pool,g.floor = g.gen_floor(g)
        end

        -- if the floor is good, generate doors for the rooms
        g.floor = g.gen_doors(g,g.floor)

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

        g = g.refresh_room(g)

        return g
    end

    ----------------------------------------------- floor system ----------------------------------------------

    g.go_to_next_floor = function(g)

        -- verify that we actually want to go to the next floor (i.e. an extra event hasn't been added by mistake)
        -- since the central room is always (0,0) and it will never go to the next floor, this can be used to make
        -- sure we only change floors once
        if((g.world.x ~= 0 and g.world.y ~= 0) or (g.world.x == 0 and g.world.y ~= 0) or (g.world.x ~= 0 and g.world.y == 0)) then
            g.world.x = 0
            g.world.y = 0
            g.world.level += 1
            g.enemy_pool = {}
            g.map_explored = {{x=0,y=0}}
            g.enemy_pool,g.floor = g.gen_floor(g)
            while(g.validate_floor(g.floor) == false) do
                g.enemy_pool = {}
                g.enemy_pool,g.floor = g.gen_floor(g)
            end
            g.floor = g.gen_doors(g,g.floor)
            g = g.refresh_room(g)
        end
        return g
    end

    g.create_possible_room_connections = function(r,name)
        return {{name=name,x=r.x+1,y=r.y},
                {name=name,x=r.x-1,y=r.y},
                {name=name,x=r.x,y=r.y+1},
                {name=name,x=r.x,y=r.y-1}}
    end

    -- create the doors for each room
    g.gen_doors = function(g,f)

        -- for each room on the floor
        for r in all(f) do
            
            -- each room has a different type of block
            local blk_num = g.block_spr_table[r.name]

            -- generate doors
            for i=3*16+1,16*16 do
                if((i%16 == 1 or i%16 == 0 or flr(i/16) == 3
                    or flr(i/16) == 15)) then
                    --r.blocks[i] = blk_num
                    --if(r.doors[1]) then

                        -- if there's a room above us
                        if(g.check_room_exists(f,{x=r.x,y=r.y+1})) then
                            if(i == 3*16+8 or i == 3*16+9) then
                                r.blocks[i] = 0
                            end
                        end
                    --end
                    --if(r.doors[2]) then

                        -- if there's a room to the left of us
                        if(g.check_room_exists(f,{x=r.x-1,y=r.y})) then
                            if(i == 8*16+1  or i == 9*16+1 ) then
                                r.blocks[i] = 0
                            end
                        end
                    --end
                    --if(r.doors[3]) then
                        -- if there's a room to the right of us
                        if(g.check_room_exists(f,{x=r.x+1,y=r.y})) then
                            if(i == 8*16+16 or i == 9*16+16) then
                                r.blocks[i] = 0
                            end
                        end
                    --end
                    --if(r.doors[4]) then
                        -- if there's a room below us
                        if(g.check_room_exists(f,{x=r.x,y=r.y-1})) then
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

    g.gen_location = function(r)
        return r
    end

    -- generate the walls for a given room
    g.gen_walls = function(r,blk_num)

        for i=3*16+1,16*16 do
        --for i=4*16,4*16 do
            if((i%16 == 1 or i%16 == 0 or flr(i/16) == 3 or flr(i/16) == 15)) then
            --if(i%16 == 0) then
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

        return r
    end

    g.create_room = function(g,f,name)
        
        local r = {}
        r.name = name or "normal"

        -- each room has a different type of block
        local blk_num = g.block_spr_table[r.name]

        -- declare the empty block table for the room
        r.blocks = {}

        -- generate walls
        g.gen_walls(r,blk_num)

        -- generate room specifics
        -- generate sacrifice room spikes
        if(r.name == "sacrifice") then
            r.blocks[9*16+8] = 11
        elseif(r.name == "boss") then
           r.blocks[9*16+8] = 12
        end

        if(r.name == "normal") then
            r.blocks[9*16+8] = blk_num
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
            local rm_cns = g.create_possible_room_connections(rooms[flr(rnd(#rooms))+1], name or "normal")

            -- pick one of the 4 possible connections at random
            local rm_num = flr(rnd(4))+1

            -- if the room doesn't exist yet
            if not g.check_room_exists(f,rm_cns[rm_num]) then

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
        if(r.name == "normal") add(g.enemy_pool,g.gen_enemies_in_room(r.name,r.x,r.y))

        -- add objects to room
        --add(g.objects,{spr=15,x=16,y=32,w=8,h=8,type="penny"})
        g.objects = {{spr=15,x=16,y=32,w=8,h=8,type="penny"}}

        -- generate the enemies
        --g.enemy_pool = {{x=0,y=0,enemies={{x=16,y=16}}}}
        

        -- return the floor
        return g.enemy_pool,f
    end

    -- check if the given room with particular coordinates exists
    g.check_room_exists = function (f,r)
        for v in all(f) do
            if(v.x == r.x and v.y == r.y) then
                return true
            end
        end
        return false
    end

    -- get the room given specific coordinates
    g.get_room = function(f,r)
        for k,v in pairs(f) do
            if(v.x == r.x and v.y == r.y) then
                return v
            end
        end
        return {name="void",x=r.x,y=r.y}
    end

    -- create a table
    g.get_room_connections = function(f,r)
        local rm_cns = {}
        add(rm_cns,globals.get_room(f,{x=r.x+1,y=r.y}))
        add(rm_cns,globals.get_room(f,{x=r.x-1,y=r.y}))
        add(rm_cns,globals.get_room(f,{x=r.x,y=r.y+1}))
        add(rm_cns,globals.get_room(f,{x=r.x,y=r.y-1}))
        return rm_cns
    end

    -- count the number of rooms that exist and that are connected to the current one
    g.count_room_connections = function(f,r)
        local num_cns = 0
        
        if(globals.get_room(f,{x=r.x+1,y=r.y}).name ~= "void") then num_cns = num_cns + 1 end
        if(globals.get_room(f,{x=r.x-1,y=r.y}).name ~= "void") then num_cns = num_cns + 1 end
        if(globals.get_room(f,{x=r.x,y=r.y+1}).name ~= "void") then num_cns = num_cns + 1 end
        if(globals.get_room(f,{x=r.x,y=r.y-1}).name ~= "void") then num_cns = num_cns + 1 end

        return num_cns
    end

    -- generate a possible floor
    g.gen_floor = function(g)

        local f = {}
        g.enemy_pool,f = g.create_room(g,f,"central")
        g.object_pool = {}

        -- generate normal rooms
        local num_normal_rooms = flr((6 + flr(rnd(3))) + g.world.level * 2)
        while(g.count_room_type(f,"normal") < num_normal_rooms) do
            g.enemy_pool,f = g.create_room(g,f,"normal")
        end

        -- generate a battle room
        while(g.count_room_type(f,"battle") == 0) do
            g.enemy_pool,f = g.create_room(g,f,"battle")
        end

        -- 25% chance to generate a sacrifice room
        if(flr(rnd(4)) == 0) then
            while(g.count_room_type(f,"sacrifice") == 0) do
                g.enemy_pool,f = g.create_room(g,f,"sacrifice")
            end
        end

        -- generate a secret room
        while(g.count_room_type(f,"secret") == 0) do
            g.enemy_pool,f = g.create_room(g,f,"secret")
        end

        -- generate a super secret room
        while(g.count_room_type(f,"super_secret") == 0) do
            g.enemy_pool,f = g.create_room(g,f,"super_secret")
        end

        -- chance to generate a sub-boss room
        if(flr(rnd(7)) == 0) then
            while(g.count_room_type(f,"sub_boss") == 0) do
                g.enemy_pool,f = g.create_room(g,f,"sub_boss")
            end
        end

        -- generate a boss room
        while(g.count_room_type(f,"boss") == 0) do
            g.enemy_pool,f = g.create_room(g,f,"boss")
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
    g.validate_floor = function(f)
        
        for r in all(f) do

            -- boss room and super secret room must have only one connection to a normal room
            if(r.name == "boss" or r.name == "super_secret") then
                if(globals.count_room_connections(f,r) == 1) then
                    local rm_cns = globals.get_room_connections(f,r)
                    for rm in all(rm_cns) do
                        if ((rm.name ~= "normal") and (rm.name ~= "void")) then
                            return false
                        end
                    end
                else
                    return false
                end
            end

            -- secret room must have at least two connections
            if(r.name == "secret") then
                if(globals.count_room_connections(f,r) < 2) then
                    return false
                end
            end
        end

        return true
    end

    -- count how many rooms exist of a certain type name
    g.count_room_type = function(f,name)
        local num = 0
        for r in all(f) do
            if(r.name == name) then
                num = num + 1
            end
        end
        return num
    end

    -- refresh game timer, enemies
    g.refresh_room = function(g)

        -- reset the timer, room blocks, room enemies, and all shots
        g.timer = 0
        g.blocks = {}
        g.enemies = {}
        --g.objects = {}
        g.particles = {}
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
                local e_pool = g.get_enemies_from_pool(g.enemy_pool,g.world.x,g.world.y)
                for e in all(e_pool) do
                    g.enemies = g.spawn_enemy(g.enemies,e.x,e.y,e.w,e.h,e.name)
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

    -- update the room when the player exits the screen
    g.update_room = function(g)

        -- go to left room
        
        if(g.p1.x <= 0 - g.p1.dx + 1) then
            g.world.x -= 1
            g.p1.x = 128 - 2 * 8
            g = g.refresh_room(g)
        end

        -- go to right room
        if(g.p1.x >= 128 - 8 - g.p1.dx - 1) then
            g.world.x += 1
            g.p1.x = 8
            g = g.refresh_room(g)
        end

        -- go to room above
        if(g.p1.y <= 24 - g.p1.dy + 1) then
            g.world.y += 1
            g.p1.y = 128 - 2 * 8
            g = g.refresh_room(g)
        end

        -- go to room below
        if(g.p1.y >= 128 - g.p1.h - g.p1.dy - 1) then
            g.world.y -= 1
            g.p1.y = 8 + 24
            g = g.refresh_room(g)
        end

        return g
    end

    ----------------------------------------------- map system ------------------------------------------------

    g.draw_map = function(g)
        for r in all(g.floor) do
            local x_dist = r.x - g.world.x
            local y_dist = r.y - g.world.y
            
            for e in all(g.map_explored) do
                if (e.x == r.x and e.y == r.y) or (abs(x_dist) + abs(y_dist) <= 1) then
                    spr(g.map_spr_table[r.name],64+r.x*8,64-r.y*8)
                    --break
                end
            end
        end

        -- draw flashing current room indicator
        if(g.timer % 30 < 15) then

            color(7)
            rect(64+g.world.x*8,64-g.world.y*8,64+g.world.x*8+7,64-g.world.y*8+7)
        end

        color(7)
        print("floor " .. g.world.level) 
    end

    -- draw minimap
    g.draw_mini_map = function(g)

        rect(104,0,127,23,7)

        
        for r in all(g.floor) do
            local x_dist = r.x - g.world.x
            local y_dist = r.y - g.world.y
            if(abs(x_dist) + abs(y_dist) <= 1) then
                spr(g.map_spr_table[r.name],112 + x_dist*8, 8 - y_dist*8)
            end
        end

        -- draw flashing current room indicator
        if(g.timer % 30 < 15) then

            color(7)
            rect(112,8,119,8+7)
        end
    end

    --------------------------------------------- physics system ----------------------------------------------

    -- check if a map cell is solid
    g.solid = function(blocks,x,y)
        local sprite = blocks[flr(x/8)+16*flr(y/8)+1]
        if(sprite ~= nil) then

            if(fget(sprite) == 1) then
                --return fget(sprite)
                return true
            end
        end
        return false
    end

    g.get_flag = function(blocks,x,y)
        return fget(blocks[flr(x/8)+16*flr(y/8)+1])
    end

    -- check if the area is solid
    g.solid_area = function(blocks,x,y,w,h,is_player)
        if(is_player and ( globals.get_flag(blocks,x+w,y) == 2 or globals.get_flag(blocks,x+w,y+h) == 2
            or globals.get_flag(blocks,x,y) == 2 or globals.get_flag(blocks,x,y+h) == 2 ) ) then
            create_event({name="go to next floor"})
        end
        return globals.solid(blocks,x+w,y) or globals.solid(blocks,x+w,y+h) or globals.solid(blocks,x,y) or globals.solid(blocks,x,y+h)
    end

    -- check if two actors have collided
    g.act_collision = function(a1,a2)
        if(a1.x<a2.x+a2.w and a1.x+a1.w>a2.x and a1.y<a2.y+a2.h and a1.y+a1.h>a2.y) return true
        return false
    end

    -- move the player, an npc or an enemy
    g.move_act = function(blocks, act, is_solid, is_player)
        
        if(is_solid) then
            if not globals.solid_area(blocks,act.x+act.dx,act.y,act.w,act.h, is_player) then
                act.x += act.dx
            else
                act.dx = 0
            end

            if not globals.solid_area(blocks,act.x,act.y+act.dy,act.w,act.h, is_player) then
                act.y += act.dy
            elseif col == 1 then
                act.dy = 0
            end
        else
            act.x += act.dx
            act.y += act.dy
        end

        -- object collision
        for o in all(globals.objects) do
            if is_player and globals.act_collision(act,o) then
                del(globals.objects,o)
                if(o.type == "penny") then
                    g.p1.money += 1
                    sfx(2)
                end
            end
        end

        return act
    end

    --
    g.act_take_dmg = function(act,shots,shot)
        if(shot.pierce ~= true) then
            del(shots,shot)
        end
        act.cur_health -= 1
        sfx(1)
        if(act.cur_health <= 0) then
            globals.particles = globals.create_death_particles(globals.particles,act.x+act.w/2,act.y+act.h/2,0.5)
        end
        return act,shots
    end

    -- update shots
    g.update_shots = function(blocks,shots)
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

            if (s.x < 8 or s.x > 120 + 8 - 8 or s.y < 24 + 8 or s.y > 120 + 8 - 8) then
                del(shots,s)
            end
            if(s.dist ~= nil) then
                if abs(s.x-s.x_init) >= s.dist or abs(s.y-s.y_init) >= s.dist then
                    del(shots,s)
                end
            end

            if globals.solid_area(blocks,s.x,s.y,s.w,s.h) and not s.spectral then
                globals.particles = globals.create_death_particles(globals.particles,s.x+s.w/2,s.y+s.h/2,0.5,7)
                del(shots,s)
                sfx(1)
            end
        end
        return shots
    end

    ---------------------------------------------- enemy system -----------------------------------------------

    g.gen_enemies = function(r)
        return r
    end

    g.gen_enemies_in_room = function(name,x,y)
        --local enemies = {}
        local enemies = {{x=8*flr(rnd(8))+32,y=8*flr(rnd(8))+32,w=8,h=8,name="demon"}}

        return {x=x,y=y,enemies=enemies}
    end

    -- ai for the enemy
    g.enemy_ai = function(e,p1,enemy_shots)
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
            add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,dir="up",type="fireball"})
            add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,dir="down",type="fireball"})
            add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,dir="left",type="fireball"})
            add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,dir="right",type="fireball"})
            e.timer = 0
        end

        e.timer = e.timer + 1

        return e,enemy_shots
    end

    -- get a list of enemies in a particular room in the pool
    g.get_enemies_from_pool = function(enemy_pool,room_x,room_y)
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
    g.remove_enemy_from_pool = function(enemy_pool,enemy,room_x,room_y)
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
    g.spawn_enemy = function(enemies,x,y, w, h, name)
        
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

    g.update_enemy = function(e)
        e,globals.enemy_shots = globals.enemy_ai(e,globals.p1,globals.enemy_shots)
        e = globals.move_act(globals.blocks, e, true)

        -- player shots hitting enemy
        for s in all(globals.p1.shots) do
            if(globals.act_collision(s,e)) then
                globals.enemy_pool = globals.remove_enemy_from_pool(globals.enemy_pool,e,globals.world.x,globals.world.y)
                del(globals.enemies,e)
                sfx(1)
                globals.particles = globals.create_death_particles(globals.particles,e.x+e.w/2,e.y+e.h/2)
                if(s.pierce ~= true) then
                    del(globals.p1.shots,s)
                end
            end
        end

        return e
    end

    ---------------------------------------------- player system ----------------------------------------------

    -- check for button presses from the player
    g.player_controls = function(p1)

        local player = p1

        -- if the player is pushing a button to move the player
        if btn(0) or btn(1) or btn(2) or btn(3) then

            
            player.num = 1
            local spd = 1.5

            -- horizontal movement
            if(btn(0)) then
                player.dx = -spd
                player.xdir = "left"
                player.lastdir = "left"
            end
            if(btn(1)) then
                player.dx = spd
                player.xdir = "right"
                player.lastdir = "right"
            end

            -- vertical movement
            if(btn(2)) then
                player.dy = -spd
                player.ydir = "up"
                player.spr = 33 + 16
                player.lastdir = "up"
            end
            if(btn(3)) then
                player.dy = spd
                player.ydir = "down"
                player.spr = 33
                player.lastdir = "down"
            end
            create_event({name="move actor",player=player})
        end

        if not btn(0) and not btn(1) then
            if globals.p1.dx ~= 0 then
                player.dx = 0
                create_event({name="stop moving horizontally",player=player})
            end
        end
        
        
        if not btn(2) and not btn(3) then
            if globals.p1.dy ~= 0 then
                player.dy = 0
                create_event({name="stop moving vertically",player=player})
            end
        end

        -- shoot
        if(btn(4) and globals.p1.can_shoot == true) then
            add(globals.p1.shots,{x=p1.x+3,y=p1.y+3,w=2,h=2,spd=2,dir=player.lastdir,faction="player",spectral=false,dist=56,x_init=p1.x,y_init=p1.y})
            globals.p1.can_shoot = false
            sfx(0)
            create_event({name="activate polling",act=p1})
        end
    end

    g.update_player = function(p1)
        -- recharge the player's shot ability
        if(p1.can_shoot == false) then
            if(p1.shot_timer >= 15) then
                p1.shot_timer = 0
                p1.can_shoot = true
                create_event({name="deactivate polling",act=p1})
            else
                p1.shot_timer += 1
            end
        end
        return p1
    end

    ---------------------------------------------- object system ----------------------------------------------

    --function gen_objects(r)
        --return r
    --end

    --------------------------------------------- particle system ---------------------------------------------

    g.create_death_particles = function(particles,x,y,r,clr)
        for i=1,8 do
            add(particles,{x=x,y=y,dx=(rnd(4)-2),dy=(rnd(4)-2),life_timer=10,clr=clr or 8,r=r})
        end
        return particles
    end

    g.update_particles = function(particles)
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
end 

function _update()
	local g = globals

    -- update the event queue
    g = g.update_events(g)

    -- listen for button presses
    g.button_listener()

	g.timer+=1

	-- gameplay
	if(g.game_state == "game") then

        if(g.p1.cur_health > 0) then

            --if(g.p1.polling == true) 
            g.p1 = g.update_player(g.p1)

			-- update the enemies
			for e in all(g.enemies) do
				e = g.update_enemy(e)
			end

            -- enemy shots hitting player
            for s in all(g.enemy_shots) do
                if(g.act_collision(s,g.p1)) then
                    
                    g.act_take_dmg(g.p1,g.enemy_shots,s)
                end
            end
        end 

		-- update the player's shots
		g.p1.shots = g.update_shots(g.blocks,g.p1.shots)

		-- update enemy shots
		g.enemy_shots = g.update_shots(g.blocks,g.enemy_shots)

		-- update the particle system
		g.particles = g.update_particles(g.particles)
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

    elseif(g.game_state == "how_to_play") then
        print("how to play", 48, 0)
        print("use directional keys to move", 0, 16)
        print("around", 0, 24)
        print("press z to shoot", 0, 32)
        print("press z to start game", 30, 120)

	elseif(g.game_state == "game") then

		-- draw player shots
		for s in all(g.p1.shots) do
			--rectfill(s.x,s.y,s.x+3,s.y+3,7)
			circfill(s.x,s.y,s.w/2,7)
		end

		-- draw enemies
		for e in all(g.enemies) do
			spr(e.spr+flr(g.timer/10)%2,e.x,e.y)
		end

		-- draw enemy shots
		for e in all(g.enemy_shots) do
			if(e.type == "crescent") then
                local rot_time = 8
                if(g.timer % rot_time < rot_time/4) then
                    spr(52,e.x,e.y)
                elseif(g.timer % rot_time < rot_time/2) then
                    spr(53,e.x,e.y)
                elseif(g.timer % rot_time < 3*rot_time/4) then
                    spr(52,e.x,e.y,1,1,true)
                else
                    spr(53,e.x,e.y,1,1,false,true)
                end
			elseif(e.type == "fireball") then
				spr(51,e.x,e.y)
			else
				circfill(e.x,e.y,1,7)
			end
		end
		
		-- draw player
        if(g.p1.cur_health > 0) then
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

        end

        -- draw health bar
        for i=1,g.p1.cur_health do
            rectfill((i-1)*4,0,(i-1)*4+1,7,8)
        end
        for i=g.p1.cur_health+1,g.p1.max_health do
            rectfill((i-1)*4,0,(i-1)*4+1,7,7)
        end

        -- draw player money
        spr(15, 48, 0)
        print("x " .. g.p1.money,58,2,7)

        -- draw player bombs
        spr(63, 76, 0)
        print("x " .. g.p1.bombs,88,2,7)
        
        g.draw_mini_map(g)

	 	-- draw blocks
	 	for i=1,(16*16) do
	 		local b = g.blocks[i]
            if(b == 12) then
                spr(b+flr(g.timer/8)%3,((i-1)*8)%128, 8*flr((i-1)/16))
            elseif(b == 4) then
                
                -- draw a strobing rainbow effect
                pal(5, flr(g.timer/8)%15+1)
                spr(8,((i-1)*8)%128, 8*flr((i-1)/16))
                pal()

            elseif(b == 5) then
                for j=0,7 do
                    -- draw a scrolling rainbow effect
                    rectfill( ((i-1)*8+j)%128, 8*flr((i-1)/16), ((i-1)*8+j)%128, 8*flr((i-1)/16)+7, g.rainbow_colors[(g.timer+j)%(#g.rainbow_colors)])
                end

	 		elseif(b ~= 0) then
	 			spr(b,((i-1)*8)%128, 8*flr((i-1)/16))
	 		end
	 	end

        -- draw objects
        for o in all(g.objects) do
            spr(o.spr,o.x,o.y)
        end

	 	-- draw particles
	 	for p in all(g.particles) do
	 		circfill(p.x,p.y,p.r,p.clr)
	 	end

	 	--print(world.x .. "," .. world.y .. " " .. p1.room.name, 0, 0, 7)

    elseif g.game_state == "map" then
        g.draw_map(g)
	end
end

__gfx__
000000005555555511111111888888888888888889ab3c12eeeeeeee333333335555555500000000000000000000000055500555555665555550055500999900
000000005566665511cccc11880000889900009989ab3c12ee8888ee33bbbb335500005500000000000000000000000055055055556556555505505509999990
00000000565665651c1cc1c180800808a0a00a0a89ab3c12e8e88e8e3b3bb3b35050050500000000000000000088000050500505565005655056650509900990
00000000566556651cc11cc180088008b00bb00b89ab3c12e88ee88e3bb33bb35005500500000000000000000086508005055050650550560565565009099990
00000000566556651cc11cc1800880083003300389ab3c12e88ee88e3bb33bb35005500500000000000000000005656505055050650550560565565009099990
00000000565665651c1cc1c180800808c0c00c0c89ab3c12e8e88e8e3b3bb3b35050050500000000000000000805656550500505565005655056650509900990
000000005566665511cccc11880000881100001189ab3c12ee8888ee33bbbb335500005500000000000000008656656555055055556556555505505509999990
000000005555555511111111888888882222222289ab3c12eeeeeeee333333335555555500000000000000005656656555500555555665555550055500999900
0000000055555555111111115555555557777755599999557755555559999995577777755aaaaaa5855555585555b55500000000000000000000000000666600
000000005000000510000001508800057000077590000995777000059999999977777777a0ffff0a80888808500bbb0500000000000000000000000006666660
0000000050000005100000015086508550007705500099055777000599999999777777775aaaaaa55888888550b0b00500000000000000000000000006600660
000000005000000510000001500565655007700550099005507770059909909977077077ff0ff0ff8808808850b0b00500000000000000000000000006066660
000000005000000510000001580565655007700550099005500777a59909909977077077ff0ff0ff88088088500bbb0500000000000000000000000006066660
00000000500000051000000186566565500000055000000550007aa59999999977777777ffffffff888888885000b0b500000000000000000000000006600660
0000000050000005100000015656656550077005500990055000aaaa59099095570770755ffffff5588888855000b0b500000000000000000000000006666660
000000005555555511111111555555555557755555599555555555aa595995955757757555ffff5555888855555bbb5500000000000000000000000000666600
00000000000888000008880090988800000888000007770000000000000000000000000000000000000000000000000000000000000000000000000000aaaa00
0000000000888880008888809098888090988880007777700000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa0
0000000008f1f1f008f1f1f0098a8a80909a8a80077070700000000000000000000000000000000000000000000000000000000000000000000000000aa00aa0
0000000008fffff008fffff00988888009888880077777700000000000000000000000000000000000000000000000000000000000000000000000000a0aaaa0
0000000001111110011111100922222009222220007777000000000000000000000000000000000000000000000000000000000000000000000000000a0aaaa0
000000000f1111f00f1111f00922228009222280070770700000000000000000000000000000000000000000000000000000000000000000000000000aa00aa0
0000000000cccc0000cccc000088880009888800007777000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa0
0000000000c0000000000c0000800000000008000070070000000000000000000000000000000000000000000000000000000000000000000000000000aaaa00
00000000000888000008880000888800000aaaa000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000007
000000000088888000888880089999800aaa000a0aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000007
00000000088888800888888089999998aaa000000aa00aa000000000000000000000000000000000000000000000000000000000000000000000000000111170
00000000088888800888888089977998aa000000aa0000aa00000000000000000000000000000000000000000000000000000000000000000000000001171110
00000000011111100111111089977998aa000000a000000a00000000000000000000000000000000000000000000000000000000000000000000000001711110
000000000f1111f00f1111f089999998aaa00000a000000a00000000000000000000000000000000000000000000000000000000000000000000000001111110
0000000000cccc0000cccc00089999800aaa000aa000000a00000000000000000000000000000000000000000000000000000000000000000000000001111110
0000000000000c0000c0000000888800000aaaa00a0000a000000000000000000000000000000000000000000000000000000000000000000000000000111100
__gff__
0001010101010101010000040202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001d0501805014050110500d05009050070500305001050240002300022000200001f0001d0001c0001c0001a000190001800016000150001400013000120001100011000100000f0000e0000c0000a000
00010000203501a35016350113500d35007350033500135000300023000e300093000230000300063000330002300343001a3001a3001b3001b3001b2001b2000620008200072000670005200042000350003500
000100001675018750197501b7501c7501e750207502375025750277502b7502e750347503d7502070002700007002c70027700227001e7001d70000000000000000000000000000000000000000000000000000
