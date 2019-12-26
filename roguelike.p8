pico-8 cartridge // http://www.pico-8.com
version 17
__lua__

function _init()

	-- initialize the global variable that holds game state data
	glbls = {game_state="opening_credits",timer=0,events={},debug=false}
    h = {}

    local g = glbls

    -- cre a save slot
    --[[
    local is_save_slot_cred = cartdata("roguelike")
    if g.debug then
        if is_save_slot_cred then
            printh("save slot cred!")
        else
            printh("save slot was not cred!")
        end
    end
    is_save_slot_cred = nil]]

    g.rm_layouts = {}
    g.rm_layouts.normal = {
                                {{i=6,j=4},{i=6,j=12},{i=12,j=12},{i=12,j=4}},
                                {{i=8,j=7},{i=8,j=8},{i=9,j=7},{i=9,j=8}}
                            }

    g.status_ailments = {"normal","stone","chill","poison"}

    g.blk_spr_table = {
        normal=1,
        central=2,
        sacrifice=3,
        secret=4,
        super_secret=5,
        battle=6,
        sub_boss=7,
        boss=8,
        shop=9,
        angel=2,
        devil=2,
        treasure=2,
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
        shop=27,
        treasure=28,
        error=29,
    }

    g.rainbow_colors = {8,9,10,11,3,12,1,2}

    g.enemy_table_name = {demon=35,skeleton=37,wizard=39}
    g.enemy_table_ai = {demon=1,skeleton=3,wizard=2}
    g.obj_table_name =   {
                                penny=15,nickel=31,dime=47,bomb=63,
                                ice_shot=66,stone_shot=67,fire_shot=68,poison_shot=69,
                            }

    g.powerup_pool = {"ice_shot"}
    g.obj_table_price = {penny=0,nickel=0,dime=0,heart=3,soul_heart=5,bomb=3}

    -- cre helper functions accessible from the global state

    ----------------------------------------------- event system ----------------------------------------------

    -- cre a new event. this function should be accessible to each function. the global event creator will help isolate functions from each other.
    function cre_event(event)
        local g = glbls
        add(g.events,event)
    end

    function upd_events(g)

        -- make sure the event queue exists before trying to access it!
        if(g.events ~= nil) then

            while(#g.events > 0) do

                local event = g.events[1]

                -- game events
                if g.game_state == "game" then
                    if event.name == "move actor" then
                        if(event.player.num == 1) then
                            g.p1 = move_act(g.blks, event.player, true, true)
                            g = upd_rm(g)
                        end

                    elseif event.name == "stop moving horizontally" then
                        if(event.player.num == 1) then
                            g.p1 = move_act(g.blks, event.player, true, true)
                        end

                    elseif event.name == "stop moving vertically" then
                        if(event.player.num == 1) then
                            g.p1 = move_act(g.blks,event.player, true, true)
                        end

                    elseif event.name == "go to next flr" then
                        g = go_to_next_flr(g)

                    elseif event.name == "cre particles" then
                        g.particles = cre_particles(g.particles,event.x+event.w/2,event.y+event.h/2,event.r,event.clr)

                    elseif event.name == "enemy death" then
                        local e = event.enemy
                        g.e_pool = rm_enemy_from_pool(g.e_pool,e,g.wrld.x,g.wrld.y)
                        del(g.enemies,e)
                        local o = {x=e.x,y=e.y,w=8,h=8,name="bomb"}
                        g.objs = spawn_obj(g.objs,o.x,o.y,o.w,o.h,o.name,g)
                        for r in all(g.o_pool) do
                            if(r.x == g.wrld.x and r.y == g.wrld.y) then
                                add(r.objs,o)
                            end
                        end
                        cre_event({name="cre particles",x=e.x,y=e.y,w=e.w,h=e.h})
                    end
                end

                -- remove the event from the queue once it's finished
                del(g.events,event)
            end
        end

        -- return the global state when we're done
        return g
    end

    -------------------------------------------- new game creation --------------------------------------------
    function cre_game(g)

        g.game_state = "game"

        -- initialize the obj table
        g.objs = {}

        -- initialize the particle system
        g.particles = {}

        -- add map toggle to pause screen
        local function map_toggle()
            if glbls.game_state ~= "map" then 
                glbls.game_state = "map" 
            else 
                glbls.game_state = "game"
            end
        end
        menuitem(1, "toggle map", map_toggle)

        -- add stats toggle to pause screen
        local function stats_toggle()
            if glbls.game_state ~= "stats" then 
                glbls.game_state = "stats" 
            else 
                glbls.game_state = "game"
            end
        end
        menuitem(2, "toggle stats", stats_toggle)

        g.map_explored = {{x=0,y=0}}

        -- set the random seed number
        --srand(0)
                
        -- setup game music and reserve channel 1
        --music(-1)
        --music(0, 0, 1)

        -- initialize the game timer
        --g.timer = 0

        -- initialize the player
        g.p1 = {x=64, y=64, dx=0, dy=0, w=7, h=7, xdir="right", ydir="down", angle=0}
        g.p1.rm = {name="central"}
        g.p1.cur_health = 6
        g.p1.max_health = 6
        g.p1.spr = 33
        g.p1.shots = {}
        g.p1.can_shoot = true
        g.p1.shot_timer = 0
        g.p1.money = 0
        g.p1.bombs = 0
        g.p1.status = "normal"
        g.p1.status_timer = 0
        g.p1.is_invincible = false
        g.p1.inv_timer = 0

        -- stats
        g.p1.spd = 1.5
        g.p1.shot_range = 56
        g.p1.shot_atk = 1
        g.p1.shot_cooldown = 15
        g.p1.shot_statuses = {}
        g.p1.luck = 0

        -- for debugging
        g.p1.current_status = 1
        --g.p1.status = g.status_ailments[g.p1.current_status]

        -- initialize the starting flr
        g.wrld = {x=0,y=0,level=0}

        g.e_pool = {}
        g.o_pool = {}

        -- cre a flr
        g.e_pool,g.o_pool,g.flr = gen_flr(g)
        
        while(validate_flr(g.flr,g) == false) do
            g.e_pool = {}
            g.o_pool = {}
            g.e_pool,g.o_pool,g.flr = gen_flr(g)
        end

        -- if the flr is good, generate doors for the rms
        g.flr = gen_doors(g,g.flr)

        -- set up the blks for the start rm (rms are 16w x 15h)
        g.blks = {}
        for r in all(g.flr) do
            if(r.x == g.wrld.x and r.y == g.wrld.y) then
                g.blks = r.blks
            end
        end

        g.bombs = {}
        g.bomb_explosions = {}

        -- initialize enemy table
        g.enemies = {}
        g.enemy_shots = {}

        g = refresh_rm(g)

        return g
    end

    ----------------------------------------------- flr system ----------------------------------------------

    function go_to_next_flr(g)

        -- verify that we actually want to go to the next flr (i.e. an extra event hasn't been added by mistake)
        -- since the central rm is always (0,0) and it will never go to the next flr, this can be used to make
        -- sure we only change flrs once
        if((g.wrld.x ~= 0 and g.wrld.y ~= 0) or (g.wrld.x == 0 and g.wrld.y ~= 0) or (g.wrld.x ~= 0 and g.wrld.y == 0)) then
            g.wrld.x = 0
            g.wrld.y = 0
            g.wrld.level += 1
            g.e_pool = {}
            g.o_pool = {}
            g.map_explored = {{x=0,y=0}}
            g.e_pool,g.o_pool,g.flr = gen_flr(g)
            while(validate_flr(g.flr,g) == false) do
                g.e_pool = {}
                g.o_pool = {}
                g.e_pool,g.o_pool,g.flr = gen_flr(g)
            end
            g.flr = gen_doors(g,g.flr)
            g = refresh_rm(g)
        end
        return g
    end

    function cre_possible_rm_connections(r,name)
        return {{name=name,x=r.x+1,y=r.y},
                {name=name,x=r.x-1,y=r.y},
                {name=name,x=r.x,y=r.y+1},
                {name=name,x=r.x,y=r.y-1}}
    end

    -- cre the doors for each rm
    function gen_doors(g,f)

        -- for each rm on the flr
        for r in all(f) do
            
            -- each rm has a different type of block
            local blk_num = g.blk_spr_table[r.name]

            -- generate doors
            for i=3*16+1,16*16 do
                if((i%16 == 1 or i%16 == 0 or flr(i/16) == 3
                    or flr(i/16) == 15)) then

                        local function setup_secret_blks(adj_rm,i)
                            if(adj_rm.name == "secret" or adj_rm.name == "super_secret" or r.name == "secret" or r.name == "super_secret") then
                                r.blks[i] = 10
                            else
                                r.blks[i] = 0
                            end
                        end

                        -- if there's a rm above us
                        if(check_rm_exists(f,{x=r.x,y=r.y+1})) then
                            if(i == 3*16+8 or i == 3*16+9) setup_secret_blks(get_rm(f,{x=r.x,y=r.y+1}),i)
                        end

                        -- if there's a rm to the left of us
                        if(check_rm_exists(f,{x=r.x-1,y=r.y})) then
                            if(i == 8*16+1  or i == 9*16+1) setup_secret_blks(get_rm(f,{x=r.x-1,y=r.y}),i)
                        end
                        -- if there's a rm to the right of us
                        if(check_rm_exists(f,{x=r.x+1,y=r.y})) then
                            if(i == 8*16+16 or i == 9*16+16) setup_secret_blks(get_rm(f,{x=r.x+1,y=r.y}),i)
                        end
                        -- if there's a rm below us
                        if(check_rm_exists(f,{x=r.x,y=r.y-1})) then
                            if(i == 15*16+8 or i == 15*16+9) setup_secret_blks(get_rm(f,{x=r.x,y=r.y-1}),i)
                        end
                end
            end
        end
        
        return f
    end

    -- generate the walls for a given rm
    function gen_walls(r,blk_num)

        for i=3*16+1,16*16 do
            if((i%16 == 1 or i%16 == 0 or flr(i/16) == 3 or flr(i/16) == 15)) r.blks[i] = blk_num
        end

        return r
    end

    -- create a rm based on the rm's name (normal, secret, shop, etc.)
    function cre_rm(g,f,name)
        
        local r = {}
        r.name = name or "normal"

        -- each rm has a different type of blk
        local blk_num = g.blk_spr_table[r.name]

        -- declare the empty blk table for the rm
        r.blks = {}

        -- generate walls
        gen_walls(r,blk_num)

        -- generate rm specifics
        -- generate sacrifice rm spikes
        if(r.name == "sacrifice") then
            r.blks[9*16+8] = 11
        elseif(r.name == "boss") then
            r.blks[9*16+8] = 12
        end

        if(r.name == "normal") then
            --r.blks[9*16+8] = blk_num
            --for m=1,#g.rm_layouts.normal do
            local m = flr(rnd(2)+1)
                for n in all(g.rm_layouts.normal[m]) do
                    r.blks[n.i*16+n.j+1] = blk_num
                end
            --end
        end

        -- generate the rm's location randomly
        -- the central rm is always at (0,0)
        if(r.name ~= "central") then
     
            -- rms that the rm can be connected to
            local rms = {}

            -- for the boss type rm
            if(r.name == "boss") then
                for i in all(f) do
                    if(i.name == "normal") then
                        add(rms,i)
                    end
                end
            else
                rms = f
            end

            -- cre possible rm connections from the randomly selected rm
            local rm_cns = cre_possible_rm_connections(rms[flr(rnd(#rms))+1], name or "normal")

            -- pick one of the 4 possible connections at random
            local rm_num = flr(rnd(4))+1

            -- if the rm doesn't exist yet
            if not check_rm_exists(f,rm_cns[rm_num]) then

                -- add the rm to the flr
                r.x = rm_cns[rm_num].x
                r.y = rm_cns[rm_num].y
                add(f,r)
            end
        else
            -- add the rm to the flr
            r.x = 0
            r.y = 0
            add(f,r)
        end

        -- add enemies to rm
        local enemy_name = "demon"
        local rand_num = flr(rnd(3))
        if (rand_num == 0) enemy_name="wizard"
        if (rand_num == 1) enemy_name="skeleton"
        if(r.name == "normal") then
            add(g.e_pool,gen_enemies_in_rm(r.blks,enemy_name,r.x,r.y))
        end

        -- add objs to rm
        add(g.o_pool,gen_objs_in_rm(r.x,r.y,r.name))

        -- return the flr
        return g.e_pool,g.o_pool,f
    end

    -- check if the given rm with particular coordinates exists
    function check_rm_exists(f,r)
        for v in all(f) do
            if(v.x == r.x and v.y == r.y) then
                return true
            end
        end
        return false
    end

    -- get the rm given specific coordinates
    function get_rm(f,r)
        for k,v in pairs(f) do
            if(v.x == r.x and v.y == r.y) then
                return v
            end
        end
        return {name="void",x=r.x,y=r.y}
    end

    -- cre a table
    function get_rm_connections(f,r)
        local rm_cns = {}
        add(rm_cns,get_rm(f,{x=r.x+1,y=r.y}))
        add(rm_cns,get_rm(f,{x=r.x-1,y=r.y}))
        add(rm_cns,get_rm(f,{x=r.x,y=r.y+1}))
        add(rm_cns,get_rm(f,{x=r.x,y=r.y-1}))
        return rm_cns
    end

    -- count the number of rms that exist and that are connected to the current one
    function count_rm_connections(f,r)
        local num_cns = 0
        
        if(get_rm(f,{x=r.x+1,y=r.y}).name ~= "void") then num_cns = num_cns + 1 end
        if(get_rm(f,{x=r.x-1,y=r.y}).name ~= "void") then num_cns = num_cns + 1 end
        if(get_rm(f,{x=r.x,y=r.y+1}).name ~= "void") then num_cns = num_cns + 1 end
        if(get_rm(f,{x=r.x,y=r.y-1}).name ~= "void") then num_cns = num_cns + 1 end

        return num_cns
    end

    -- generate a possible flr
    function gen_flr(g)

        local f = {}
        g.e_pool,g.o_pool,f = cre_rm(g,f,"central")

        -- generate normal rms
        local num_normal_rms = flr((4 + flr(rnd(3))) + g.wrld.level)
        while(count_rm_type(f,"normal") < num_normal_rms) do
            g.e_pool,g.o_pool,f = cre_rm(g,f,"normal")
        end

        -- generate a battle rm
        while(count_rm_type(f,"battle") == 0) do
            g.e_pool,g.o_pool,f = cre_rm(g,f,"battle")
        end

        -- generate a shop
        while(count_rm_type(f,"shop") == 0) do
            g.e_pool,g.o_pool,f = cre_rm(g,f,"shop")
        end

        -- 25% chance to generate a sacrifice rm
        if(flr(rnd(4)) == 0) then
            while(count_rm_type(f,"sacrifice") == 0) do
                g.e_pool,g.o_pool,f = cre_rm(g,f,"sacrifice")
            end
        end

        -- generate a treasure rm
        while(count_rm_type(f,"treasure") == 0) do
            g.e_pool,g.o_pool,f = cre_rm(g,f,"treasure")
        end

        -- generate a secret rm
        while(count_rm_type(f,"secret") == 0) do
            g.e_pool,g.o_pool,f = cre_rm(g,f,"secret")
        end

        -- generate a super secret rm
        while(count_rm_type(f,"super_secret") == 0) do
            g.e_pool,g.o_pool,f = cre_rm(g,f,"super_secret")
        end

        -- chance to generate a sub-boss rm
        if(flr(rnd(7)) == 0) then
            while(count_rm_type(f,"sub_boss") == 0) do
                g.e_pool,g.o_pool,f = cre_rm(g,f,"sub_boss")
            end
        end

        -- generate a boss rm
        while(count_rm_type(f,"boss") == 0) do
            g.e_pool,g.o_pool,f = cre_rm(g,f,"boss")
        end

        --[[
        while(g.count_rm_type(f,"devil") == 0 and g.count_rm_type(f,"angel") == 0) do
            if(flr(rnd(2)) == 0) then
                g.e_pool,g.o_pool,f = g.cre_rm(g,f,"angel")
            else
                g.e_pool,g.o_pool,f = g.cre_rm(g,f,"devil")
            end
        end]]
        

        return g.e_pool,g.o_pool,f
    end

    -- validates if a flr meets the necessary requirements
    function validate_flr(f,g)
        
        for r in all(f) do

            -- all rms must be connected
            if(count_rm_connections(f,r) < 1) then
                return false
            end
            
            --[[
            if(r.name == "boss") then
                if(g.count_rm_connections(f,r) == 2) then
                    local rm_cns = g.get_rm_connections(f,r)
                    for rm in all(rm_cns) do
                        if ((rm.name ~= "normal") and (rm.name ~= "void") and rm.name == "angel" and rm.name == "devil") then
                            return false
                        end
                    end
                else
                    return false
                end
            end]]

            -- boss rm and super secret rm must have only one connection to a normal rm
            if(r.name == "boss" or r.name == "super_secret") then
                if(count_rm_connections(f,r) == 1) then
                    local rm_cns = get_rm_connections(f,r)
                    for rm in all(rm_cns) do
                        if ((rm.name ~= "normal") and (rm.name ~= "void")) then
                            return false
                        end
                    end
                else
                    return false
                end
            end

            -- secret rm must have at least two connections
            if(r.name == "secret") then
                if(count_rm_connections(f,r) < 2) then
                    return false
                end
            end

            --[[
            if(r.name == "angel" or r.name == "devil") then
                if(g.count_rm_connections(f,r) == 1) then
                    local rm_cns = g.get_rm_connections(f,r)
                    for rm in all(rm_cns) do
                        if ((rm.name ~= "boss") and (rm.name ~= "void")) then
                            return false
                        end
                    end
                else
                    return false
                end
            end]]
        end

        return true
    end

    -- count how many rms exist of a certain type name
    function count_rm_type(f,name)
        local num = 0
        for r in all(f) do
            if(r.name == name) then
                num = num + 1
            end
        end
        return num
    end

    -- get the rm we are currently in
    --[[
    function get_current_rm(g)
        for r in all(g.flr) do
            if(r.x == g.wrld.x and r.y == g.wrld.y) then
                return r
            end
        end
    end]]

    -- refresh game timer, enemies
    function refresh_rm(g)

        -- reset the timer, rm blks, rm enemies, rm objs and all shots
        g.timer = 0
        g.blks = {}
        g.enemies = {}
        g.objs = {}
        g.particles = {}
        g.p1.shots = {}
        g.bombs = {}
        g.bomb_explosions = {}
        g.enemy_shots = {}

        for i=1,16*16 do
            add(g.blks,0)
        end

        -- for all rms on the flr
        for r in all(g.flr) do

            -- for the rm we are in
            if(r.x == g.wrld.x and r.y == g.wrld.y) then

                -- setup the rm's blk table
                g.blks = r.blks

                -- destroy nearby bombable blks
                for m=-1,1 do
                    for n=-1,1 do
                        local blk_num = g.blks[flr(g.p1.x/8+m)+16*(flr(g.p1.y/8)+n)+1]
                        if(blk_num == 10) then
                            g.blks[flr(g.p1.x/8+m)+16*(flr(g.p1.y/8)+n)+1] = 0
                        end
                    end
                end
                        --for i=1,64 do
                        --local b = {x=((i-1)*8)%128,y=8*flr((i-1)/16),w=8,h=8}

                -- get enemies from the pool
                local e_pool = get_enemies_from_pool(g.e_pool,g.wrld.x,g.wrld.y)
                for e in all(e_pool) do
                    g.enemies = spawn_enemy(g.enemies,e.x,e.y,e.w,e.h,e.name,e.is_boss,g)
                end

                -- get objs from the pool
                local o_pool = get_objs_from_pool(g.o_pool,g.wrld.x,g.wrld.y)
                
                -- populate rm objs with obj pool
                for o in all(o_pool) do
                    g.objs = spawn_obj(g.objs,o.x,o.y,o.w,o.h,o.name,g)
                end

                -- has the player been in this rm yet?
                local rm_expl = false
                for e in all(g.map_explored) do
                    if(e.x == g.wrld.x and e.y == g.wrld.y) then
                        rm_expl = true
                        break
                    end
                end
                if(not rm_expl) add(g.map_explored,{x=g.wrld.x,y=g.wrld.y})

                -- set the music up
                if (r.name == "secret" or r.name == "super_secret") then
                    music(0)
                else
                    music(-1)
                end

                g.wrld.name = r.name

                -- break as we found the rm we wanted
                break
            end
        end

        return g
        --spawn_time = flr(rnd(2*30)) + 1*30
    end

    -- upd the rm when the player exits the screen
    function upd_rm(g)

        -- go to left rm
        if(g.p1.x <= 0 - g.p1.dx + 1) then
            g.wrld.x -= 1
            g.p1.x = 128 - 2 * 8
            g = refresh_rm(g)
        end

        -- go to right rm
        if(g.p1.x >= 128 - 8 - g.p1.dx - 1) then
            g.wrld.x += 1
            g.p1.x = 8
            g = refresh_rm(g)
        end

        -- go to rm above
        if(g.p1.y <= 24 - g.p1.dy + 1) then
            g.wrld.y += 1
            g.p1.y = 128 - 2 * 8
            g = refresh_rm(g)
        end

        -- go to rm below
        if(g.p1.y >= 128 - g.p1.h - g.p1.dy - 1) then
            g.wrld.y -= 1
            g.p1.y = 8 + 24
            g = refresh_rm(g)
        end

        return g
    end

    ----------------------------------------------- map system ------------------------------------------------

    function draw_map(g)
        for r in all(g.flr) do
            local x_dist = r.x - g.wrld.x
            local y_dist = r.y - g.wrld.y
            
            for e in all(g.map_explored) do
                if ((e.x == r.x and e.y == r.y) or ((abs(x_dist) <=1 and abs(y_dist) <= 1)
                    and r.name ~= "secret" and r.name ~= "super_secret")) then
                    spr(g.map_spr_table[r.name],64+r.x*8,64-r.y*8)
                end
            end
        end

        -- draw flashing current rm indicator
        if(g.timer % 30 < 15) then
            color(7)
            rect(64+g.wrld.x*8,64-g.wrld.y*8,64+g.wrld.x*8+7,64-g.wrld.y*8+7)
        end

        color(7)
        print("flr " .. g.wrld.level) 
    end

    -- draw minimap
    function draw_mini_map(g)

        rect(104,0,127,23,7)

        for r in all(g.flr) do
            local x_dist = r.x - g.wrld.x
            local y_dist = r.y - g.wrld.y
            for e in all(g.map_explored) do
                if ((abs(x_dist) <= 1 and abs(y_dist) <= 1)
                    and (r.name ~= "secret" or (e.x == r.x and e.y == r.y))
                    and (r.name ~= "super_secret" or (e.x == r.x and e.y == r.y))) then
                    spr(g.map_spr_table[r.name],112 + x_dist*8, 8 - y_dist*8)
                end
            end
        end

        -- draw flashing current rm indicator
        if(g.timer % 30 < 15) then

            color(7)
            rect(112,8,119,8+7)
        end
    end

    --------------------------------------------- physics system ----------------------------------------------

    function get_blk(blks,x,y)
        return blks[flr(x/8)+16*flr(y/8)+1]
    end

    -- check if a map cell is solid
    function solid(blks,x,y)
        local blk = get_blk(blks,x,y)
        if(blk ~= nil) then

            if(fget(blk) == 1 or fget(blk) == 5) then
                return true
            end
        end
        return false
    end

    -- get the flag of a particular blk by coordinates
    function get_flag(blks,x,y)
        return fget(get_blk(blks,x,y))
    end

    -- check if the area is solid
    function solid_area(blks,x,y,w,h,is_player)
        if(is_player and (get_flag(blks,x+w,y) == 2 or get_flag(blks,x+w,y+h) == 2
            or get_flag(blks,x,y) == 2 or get_flag(blks,x,y+h) == 2 ) ) then
            cre_event({name="go to next flr"})
        end
        return solid(blks,x+w,y) or solid(blks,x+w,y+h) or solid(blks,x,y) or solid(blks,x,y+h)
    end

    -- check if two actors have collided
    function act_col(a1,a2)
        if(a1.x<a2.x+a2.w and a1.x+a1.w>a2.x and a1.y<a2.y+a2.h and a1.y+a1.h>a2.y) return true
        return false
    end

    -- move the player, an npc or an enemy
    function move_act(blks, act, is_solid, is_player)
        local g = glbls


        if(is_solid) then
            if not solid_area(blks,act.x+act.dx,act.y,act.w,act.h, is_player) then
                act.x += act.dx
            else
                act.dx = 0
            end

            if not solid_area(blks,act.x,act.y+act.dy,act.w,act.h, is_player) then
                act.y += act.dy
            elseif col == 1 then
                act.dy = 0
            end
        else
            act.x += act.dx
            act.y += act.dy
        end

        -- obj collision
        for o in all(g.objs) do
            if is_player and act_col(act,o) then

                local get_item = false

                if(g.wrld.name == "shop") then
                    if(g.p1.money >= g.obj_table_price[o.name]) then
                        g.p1.money -= g.obj_table_price[o.name]
                        get_item = true
                    end
                else
                    get_item = true
                end

                if(get_item) then
                    remove_obj_from_pool(g.o_pool,o,g.wrld.x,g.wrld.y)
                    del(g.objs,o)
                    if(o.name == "penny") then
                        g.p1.money += 1
                    elseif(o.name == "nickel") then
                        g.p1.money += 5
                    elseif(o.name == "dime") then
                        g.p1.money += 10
                    elseif(o.name == "bomb") then
                        g.p1.bombs += 1
                    elseif(o.name == "ice_shot") then
                        add(g.p1.shot_statuses,"chill")
                        for p in all(g.powerup_pool) do
                            if(p == o.name) then
                                del(g.powerup_pool,p)
                            end
                        end
                    end
                    sfx(2)
                end
            end
        end

        return act
    end

    -- actor takes damage
    function act_take_dmg(act,shots,shot,is_enemy)
        if(act.status ~= "stone" and not act.is_invincible) then
            if(shot ~= nil) then
                if(shot.pierce ~= true) del(shots,shot)
                if(shot.status ~= nil and act.status == "normal") act.status = shot.status
            end
            act.cur_health -= shot.atk or 1
            act.is_invincible = true
            sfx(1)
            if(act.cur_health <= 0) then
                cre_event({name="cre particles",x=act.x,y=act.y,w=act.w,h=act.h})
                if(is_enemy) cre_event({name="enemy death", enemy=act})
            end
        end
        return act,shots
    end

    -- upd shots
    function upd_shots(blks,shots)
        for s in all(shots) do

            -- upd shots
            s.x += s.spd * cos(s.angle/360)
            s.y += s.spd * sin(s.angle/360) 

            -- remove shots that go out of screen
            if (s.x < 8 or s.x > 120 + 8 - 8 or s.y < 24 + 8 or s.y > 120 + 8 - 8) then
                del(shots,s)
            end

            -- if a shot should be removed after traveling a certain distance
            if(s.dist ~= nil) then
                if abs(s.x-s.x_init) >= s.dist or abs(s.y-s.y_init) >= s.dist then
                    del(shots,s)
                end
            end

            -- if a shot hits a blk
            if solid_area(blks,s.x,s.y,s.w,s.h) and not s.spectral then
                local clr = 7
                if(s.status == "chill") clr = 12
                if(s.status == "fire") clr = 8
                if(s.status == "poison") clr = 11
                if(s.status == "stone") clr = 5
                cre_event({name="cre particles",x=s.x,y=s.y,w=s.w,h=s.h,clr=clr})
                del(shots,s)
                sfx(1)
            end
        end
        return shots
    end

    ---------------------------------------------- enemy system -----------------------------------------------

    function gen_enemies_in_rm(blks,name,x,y)
        local enemies = {}

        local valid_enemies = false

        while(valid_enemies == false) do
            enemies = {{x=8*flr(rnd(8))+32,y=8*flr(rnd(8))+32,w=8,h=8,name=name}}
            valid_enemies = true
            for e in all(enemies) do
                local f = get_flag(blks,e.x,e.y)
                if(f == 1 or f == 5) valid_enemies = false
            end
        end

        return {x=x,y=y,enemies=enemies}
    end

    -- ai for the enemy
    function enemy_ai(e,p1,enemy_shots)

        if(e.status ~= "stone" and e.status ~= "paralysis") then

            if(e.ai == 1) then
                if(e.timer == 60) then

                    for i=0,3 do
                        add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,angle=i*90,name="fireball",atk=1})
                    end

                end
            elseif(e.ai == 2) then
                if(e.timer == 60) then


                    for i=0,3 do
                        add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,angle=i*90,name="crescent",spectral=true,atk=1})
                    end

                    local dist_x = p1.x - e.x
                    local dist_y = p1.y - e.y

                    -- player is to the down right of enemy
                    --if(p1.x >= e.x and p1.y >= e.y) then
                        --add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,drct="down",name="fireball"})
                        --add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,drct="down_left",name="fireball"})
                        --add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,drct="down_right",name="fireball"})
                end
            elseif(e.ai == 3) then
                if(e.timer == 60) then
                    for i=0,3 do
                        add(enemy_shots,{x=e.x,y=e.y,w=8,h=8,spd=2,angle=i*90,name="iceball",status="chill",atk=1})
                    end

                end
            end

            -- follow pattern
            local spd = e.spd
            if(e.status == "chill") spd /= 2
            if(e.timer < 30) then
                e.dx = 0
                e.dy = 0

            elseif(e.timer >= 30 and e.timer < 60) then
                if e.x < p1.x - 1 then
                    e.dx = spd
                elseif e.x > p1.x + 1 then
                    e.dx = -spd
                else
                    e.dx = 0
                end

                if e.y < p1.y - 1 then
                    e.dy = spd
                elseif e.y > p1.y + 1 then
                    e.dy = -spd
                else
                    e.dy = 0
                end
                
            elseif(e.timer >= 60) then
                e.timer = 0
            end
        end

        e.timer = e.timer + 1

        return e,enemy_shots
    end

    -- get a list of enemies in a particular rm in the pool
    function get_enemies_from_pool(e_pool,rm_x,rm_y)
        -- check all the rms in the enemy pool
        for r in all(e_pool) do

            -- if we find the rm we are looking for, get the list of enemies in it
            if(r.x == rm_x and r.y == rm_y) then
                return r.enemies
            end
        end

        -- if there is no entry in the enemy pool table, return an empty list
        return {}
    end

    -- delete a particular enemy from the pool based on a certain rm and enemy name
    function rm_enemy_from_pool(e_pool,enemy,rm_x,rm_y)
        -- for each rm in the enemy pool
        for r in all(e_pool) do

            -- if the rm in the pool is the one we want
            if(r.x == rm_x and r.y == rm_y) then

                -- search the table of enemies in the rm
                for e in all(r.enemies) do

                    -- if we found the name of the enemy that we want, delete it
                    if(enemy.name == e.name) then
                        del(r.enemies,e)
                    end
                end
            end
        end
        return e_pool
    end

    -- spawn enemy function
    function spawn_enemy(enemies,x,y, w, h, name, is_boss, g)
        
        local e = {}
        e.x = x or 0
        e.y = y or 0
        e.dx = 0
        e.dy = 0
        e.w = w or 8
        e.h = h or 8
        e.name = name or "default"
        e.spd = 0.5
        e.spr = g.enemy_table_name[e.name]
        e.ai = g.enemy_table_ai[e.name]
        e.is_boss = is_boss or false
        e.timer = 0
        e.cur_health = 3
        e.status = "normal"
        e.status_timer = 0
        e.is_invincible = false
        e.inv_timer = 0

        add(enemies,e)

        return enemies
    end

    -- upd the enemy
    function upd_enemy(e,g)
        e,g.enemy_shots = enemy_ai(e,g.p1,g.enemy_shots)
        e = move_act(g.blks, e, true)

        -- player shots hitting enemy
        for s in all(g.p1.shots) do
            if(act_col(s,e)) act_take_dmg(e,g.p1.shots,s,true)
        end

        -- cure status conditions
        if(e.status ~= "normal") then
            e.status_timer += 1
            if(e.status_timer >= 60) then
                e.status = "normal"
                e.status_timer = 0
            end
        else
            e.status_timer = 0
        end

        if(e.is_invincible) then
            e.inv_timer+=1
            if(e.inv_timer >= 10) then
                e.inv_timer=0
                e.is_invincible = false
            end
        end

        return e,g
    end

    ---------------------------------------------- player system ----------------------------------------------

    -- check for button presses from the player
    function player_controls(p1,g)

        local player = p1

        -- if the 'x' key is pressed
        if(btnp(5)) then 
            if(g.debug) then
                --glbls.p1.current_status = (g.p1.current_status + 1) % #g.status_ailments + 1
                --glbls.p1.status = g.status_ailments[glbls.p1.current_status]
                g.p1.current_status += 1
                g.p1.status = g.status_ailments[g.p1.current_status % #g.status_ailments + 1]
            else

                -- drop a bomb at the player's current pos
                if(g.p1.bombs >= 1) then
                    add(g.bombs,{x=g.p1.x,y=g.p1.y,timer=0})
                    g.p1.bombs -= 1
                end
            end
        end

        -- make sure the player isn't turned to stone, paralyzed or dead
        if(p1.status ~= "stone" and p1.status ~= "paralysis" and p1.cur_health > 0) then

            -- if the player is pushing a button to move the player
            if btn(0) or btn(1) or btn(2) or btn(3) then

                
                player.num = 1
                local spd = g.p1.spd
                if(p1.status == "chill") spd /= 2

                -- horizontal movement
                if(btn(0)) then
                    player.dx = -spd
                    player.xdir = "left"
                    player.angle = 180
                end
                if(btn(1)) then
                    player.dx = spd
                    player.xdir = "right"
                    player.angle = 0
                end

                -- vertical movement
                if(btn(2)) then
                    player.dy = -spd
                    player.ydir = "up"
                    player.spr = 33 + 16
                    player.angle = 90
                end
                if(btn(3)) then
                    player.dy = spd
                    player.ydir = "down"
                    player.spr = 33
                    player.angle = 270
                end
                cre_event({name="move actor",player=player})
            end

            -- stop horizontal movement
            if not btn(0) and not btn(1) then
                if p1.dx ~= 0 then
                    player.dx = 0
                    cre_event({name="stop moving horizontally",player=player})
                end
            end
            
            -- stop vertical movement
            if not btn(2) and not btn(3) then
                if p1.dy ~= 0 then
                    player.dy = 0
                    cre_event({name="stop moving vertically",player=player})
                end
            end

            -- shoot
            if(btn(4) and p1.can_shoot == true) then
                local shot_status = nil
                for s in all(g.p1.shot_statuses) do
                    -- chance of player shot being special based on luck
                    if(p1.luck >= flr(rnd(4))) then
                        shot_status = s
                        break
                    end
                end

                add(p1.shots, {
                                    x=p1.x+3,y=p1.y+3,w=2,h=2,
                                    angle=player.angle,
                                    x_init=p1.x,
                                    y_init=p1.y,
                                    spd=2,
                                    dist=p1.shot_range,
                                    spectral=false,
                                    status = shot_status,
                                    atk=p1.shot_atk
                                }
                    )
                p1.can_shoot = false
                sfx(0)
                --cre_event({name="activate polling",act=p1})
            end
        end

        return g
    end

    -- upd the player based on timers
    function upd_player(p1)
        -- recharge the player's shot ability
        if(p1.can_shoot == false) then
            if(p1.shot_timer >= g.p1.shot_cooldown) then
                p1.shot_timer = 0
                p1.can_shoot = true
            else
                p1.shot_timer += 1
            end
        end

        -- cure status conditions
        if(p1.status ~= "normal") then
            p1.status_timer += 1
            if(p1.status_timer >= 60) then
                p1.status = "normal"
                p1.status_timer = 0
            end
        else
            p1.status_timer = 0
        end

        if(p1.is_invincible) then
            p1.inv_timer+=1
            if(p1.inv_timer >= 30) then
                p1.inv_timer=0
                p1.is_invincible = false
            end
        end

        return p1
    end

    function upd_bombs(bombs)
        for b in all(bombs) do
            b.timer += 1
            if(b.timer > 30) then
                del(bombs,b)
                add(g.bomb_explosions,{x=b.x,y=b.y,w=24,h=24,timer=0})
                sfx(5)
            end
        end
        return bombs
    end

    ---------------------------------------------- obj system ----------------------------------------------

    -- delete a particular obj from the pool based on a certain rm
    function remove_obj_from_pool(o_pool,obj,rm_x,rm_y)
        -- for each rm in the obj pool
        for r in all(o_pool) do

            -- if the rm in the pool is the one we want
            if(r.x == rm_x and r.y == rm_y) then

                -- search the table of enemies in the rm
                for o in all(r.objs) do

                    -- if we found the obj that we want, delete it
                    if(o.x == obj.x and o.y == obj.y) then
                        del(r.objs,o)
                    end
                end
            end
        end
        return o_pool
    end

    function get_objs_from_pool(o_pool,rm_x,rm_y)
        -- check all the rms in the enemy pool
        for r in all(o_pool) do

            -- if we find the rm we are looking for, get the list of objs in it
            if(r.x == rm_x and r.y == rm_y) return r.objs
        end

        -- if there is no entry in the obj pool table, return an empty list
        return {}
    end

    -- spawn obj function
    function spawn_obj(objs,x,y, w, h, name, g)
        
        local o = {}
        o.x = x or 0
        o.y = y or 0
        o.w = w or 8
        o.h = h or 8
        o.name = name or "penny"
        o.spr = g.obj_table_name[o.name]
        o.price = g.obj_table_price[o.name]
        o.timer = 0

        add(objs,o)

        return objs
    end

    function gen_objs_in_rm(x,y,rm_name)
        local objs = {}
        --{{x=8*flr(rnd(8))+32,y=8*flr(rnd(8))+32,w=8,h=8,name=name or "penny"}}

        local obj_name = ""
        if(rm_name == "secret") obj_name = "penny"
        if(rm_name == "super_secret") obj_name = "nickel"

        if(rm_name == "secret" or rm_name == "super_secret") then
            add(objs,{x=8+16,y=32+16,w=8,h=8,name=obj_name})
            add(objs,{x=128-8-16,y=32+16,w=8,h=8,name=obj_name})
            add(objs,{x=8+16,y=128-16-16,w=8,h=8,name=obj_name})
            add(objs,{x=128-8-16,y=128-16-16,w=8,h=8,name=obj_name})

        elseif(rm_name == "shop") then
            add(objs,{x=8+34,y=52+16,w=8,h=8,name="bomb"})
            add(objs,{x=8+50,y=52+16,w=8,h=8,name="bomb"})
            add(objs,{x=8+66,y=52+16,w=8,h=8,name="bomb"})
        
        elseif(rm_name == "treasure") then

            if(#g.powerup_pool >= 1) then
                -- pick a powerup from the powerup pool
                local powerup = flr(rnd(#g.powerup_pool)) + 1

                add(objs,{x=8+50,y=52+16,w=8,h=8,name=g.powerup_pool[powerup]})
            end
        end

        return {x=x,y=y,objs=objs}
    end

    --------------------------------------------- particle system ---------------------------------------------

    function cre_particles(particles,x,y,r,clr)
        for i=1,8 do
            add(particles,{x=x,y=y,dx=(rnd(4)-2),dy=(rnd(4)-2),life_timer=10,clr=clr or 8,r=r or 0.5})
        end
        return particles
    end

    function upd_particles(particles)
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
	local g = glbls

    -- upd the event queue
    g = upd_events(g)

    -- title menu
    if(g.game_state == "title") then
        if btn(4) then
            g.game_state = "how_to_play"
            sfx(2)
        end

    -- how to play
    elseif(g.game_state == "how_to_play") then
        if btn(4) then
            g = cre_game(g)
            sfx(2)
        end
    end

	g.timer = (g.timer + 1) % 32000
	
    if(g.game_state == "opening_credits") then
        if(g.timer < 60 and btn(4)) g.timer = 60
        if(g.timer >= 90) g.game_state = "title"
    end

    -- gameplay
	if(g.game_state == "game") then

        if(g.p1.cur_health > 0) then

            g.p1 = upd_player(g.p1)
            g = player_controls(g.p1,g)

			-- upd the enemies
			for e in all(g.enemies) do
				e,g = upd_enemy(e,g)
			end

            -- enemy shots hitting player
            for s in all(g.enemy_shots) do
                if(act_col(s,g.p1)) act_take_dmg(g.p1,g.enemy_shots,s)
            end
        else
            if btnp(5) then
                g = cre_game(g)
                sfx(2)
            end
        end 

		-- upd the player's shots
		g.p1.shots = upd_shots(g.blks,g.p1.shots)

		-- upd enemy shots
		g.enemy_shots = upd_shots(g.blks,g.enemy_shots)

        -- upd bombs
        g.bombs = upd_bombs(g.bombs)

        -- upd bomb explosions
        for e in all(g.bomb_explosions) do
            e.timer += 1
            if(e.timer >= 15) del(g.bomb_explosions,e)

            local e_aoe = {x=e.x-8,y=e.y-8,w=24,h=24}

            -- destroy bomb blks
            for i=1,(16*16) do
                local b = {x=((i-1)*8)%128,y=8*flr((i-1)/16),w=8,h=8}
                if(get_flag(g.blks,b.x,b.y) == 5) then
                    if(act_col(b,e_aoe)) g.blks[i] = 0
                end
            end

            for enemy in all(g.enemies) do
                if(act_col(enemy,e_aoe)) act_take_dmg(enemy,{},{atk=2},true) --cre_event({name = "enemy death",enemy=enemy})
            end
        end

		-- upd the particle system
		g.particles = upd_particles(g.particles)
	end
end

function _draw()
	local g = glbls

	-- clear the screen with black
	cls()
    color(7)

    if(g.game_state == "opening_credits") then
        -- show the roc studios logo
        sspr(32*3, 32*3, 32, 32, 32, 16, 64, 64)
        sspr(32*2, 32*3+16, 32, 16, 32, 16+64, 64, 32)

        -- player can skip the logo
        if(g.timer < 60 and btnp(4)) then
            g.timer = 60
        end

        -- screen wipe after 60 frames
        if(g.timer >= 60) then
            rectfill(0, 0, 128, (g.timer-60)*5, 0)
            color(7)
        end

	elseif(g.game_state == "title") then
		print("untitled roguelike", 32, 0)
		print("press z to start", 36, 64)
		print("v0.4.0.1",96,120)

    elseif(g.game_state == "how_to_play") then
        print("how to play", 48, 0)
        print("use directional keys to move", 0, 16)
        print("around.", 0, 24)
        print("press z to shoot.", 0, 32)
        print("press x to drop bombs.", 0, 40)
        print("coins can be used to buy items", 0, 56)
        print("in shops.", 0, 64)
        print("bombs can be used to reveal", 0, 80)
        print("hidden rms by destroying the", 0, 88)
        print("middle of some walls.", 0, 96)
        print("press z to start game", 30, 120)

	elseif(g.game_state == "game") then

        -- draw shop prices
        if(g.wrld.name == "shop") then
            print("3",44,80,7)
            print("3",60,80,7)
            print("3",76,80,7)
        end

		-- draw player shots
		for s in all(g.p1.shots) do
            local clr = 7
            if(s.status == "fire") clr = 8
            if(s.status == "poison") clr = 11
            if(s.status == "chill") clr = 12
            if(s.status == "stone") clr = 5
			circfill(s.x,s.y,s.w/2,clr)
		end

		-- draw enemies
		for e in all(g.enemies) do
            if(e.is_invincible == false or g.timer % 2 == 0) then
                if(e.status == "chill") then
                    --print(e.status,0,8)
                    for c=0,15 do
                        pal(c,12)
                    end
                end
    			spr(e.spr+flr(g.timer/10)%2,e.x,e.y)
                pal()
            end
		end

		-- draw enemy shots
		for e in all(g.enemy_shots) do
			if(e.name == "crescent") then
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
			elseif(e.name == "fireball") then
				spr(51,e.x,e.y)
            elseif(e.name == "iceball") then
                spr(54,e.x,e.y)
			else
				circfill(e.x,e.y,1,7)
			end
		end
		
        -- draw bombs on flr
        for b in all(g.bombs) do
            spr(63,b.x,b.y)
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
        
        draw_mini_map(g)

	 	-- draw blks
	 	for i=1,(16*16) do
	 		local b = g.blks[i]

            if(g.wrld.name == "secret") then
                if(b == g.blk_spr_table["secret"] or b == 10) then
                
                    -- draw a strobing rainbow effect
                    pal(5, flr(g.timer/8)%15+1)
                    spr(8,((i-1)*8)%128, 8*flr((i-1)/16))
                    pal()
                end
            elseif(g.wrld.name == "super_secret") then
                if(b == g.blk_spr_table["super_secret"] or b == 10) then
                    for j=0,7 do
                        -- draw a scrolling rainbow effect
                        rectfill( ((i-1)*8+j)%128, 8*flr((i-1)/16), ((i-1)*8+j)%128, 8*flr((i-1)/16)+7, g.rainbow_colors[(g.timer+j)%(#g.rainbow_colors)])
                    end
                end
            else
                if(b == 12) then
                    spr(b+flr(g.timer/8)%3,((i-1)*8)%128, 8*flr((i-1)/16))

                -- bomb walls
                elseif(b == 10) then
                    spr(g.blk_spr_table[g.wrld.name],((i-1)*8)%128, 8*flr((i-1)/16))

    	 		elseif(b ~= 0) then
    	 			spr(b,((i-1)*8)%128, 8*flr((i-1)/16))
    	 		end
            end
	 	end

        -- draw objs
        for o in all(g.objs) do
            spr(o.spr,o.x,o.y)
        end

        -- draw bomb explosions
        for e in all(g.bomb_explosions) do
            --spr(44,e.x,e.y)
            for i=-8,8,8 do
                for j=-8,8,8 do
                    spr(44+flr(e.timer/5),e.x+i,e.y+j)
                end
            end
            --rectfill(e.x,e.y,e.x+e.w,e.y+e.h,7)
        end

        -- draw player
        if(g.p1.cur_health > 0) then
            if(g.p1.is_invincible == false or g.timer % 2 == 0) then
                if(g.p1.status == "stone") then
                    pal(1,5)
                    pal(8,5)
                    pal(12,6)
                    pal(15,7)
                    if(g.p1.xdir == "left") then
                        spr(g.p1.spr, g.p1.x, g.p1.y, 1, 1, true)
                    else
                        spr(g.p1.spr, g.p1.x, g.p1.y)
                    end
                else
                    if(g.p1.status == "chill") then
                        pal(8,12)
                        pal(15,12)
                    elseif(g.p1.status == "poison") then
                        pal(1,3)
                        pal(8,3)
                        pal(12,3)
                        pal(15,11)
                    end
                    if(g.p1.xdir == "left") then
                        spr(g.p1.spr+flr(g.timer/10)%2, g.p1.x, g.p1.y, 1, 1, true)
                    else
                        spr(g.p1.spr+flr(g.timer/10)%2, g.p1.x, g.p1.y)
                    end

                end
            end
        else
            rectfill(24,64,96,76,0)
            color(7)
            print("game over.\npress x to restart", 24, 64,7)
        end
        pal()

	 	-- draw particles
	 	for p in all(g.particles) do
	 		circfill(p.x,p.y,p.r,p.clr)
	 	end

    elseif g.game_state == "map" then
        draw_map(g)

    elseif g.game_state == "stats" then
        rect(0,0,127,127,7)
        print("stats",56,4)
        print("atk: " .. g.p1.shot_atk,32,48)
        print("shot cooldown: " .. g.p1.shot_cooldown,32,56)
        print("shot range: " .. g.p1.shot_range,32,64)
        print("speed: " .. g.p1.spd,32,72)
        print("luck: " .. g.p1.luck,32,80)
        --spr(g.obj_table_name["ice_shot"],4,116)
        for p in all(g.p1.shot_statuses) do
            if(p == "chill") then
                spr(g.obj_table_name["ice_shot"],4,116)
            end
        end
	end

    --print(g.timer,0,0,7)
end

__gfx__
000000005555555511111111888888888888888889ab3c12eeeeeeeecccccccc5555555533333333555555570000000055500555555665555550055500999900
000000005566665511cccc11880000889900009989ab3c12ee8888eecc0000cc5500005533bbbb33500000070000000055055055556556555505505509999990
00000000565665651c1cc1c180800808a0a00a0a89ab3c12e8e88e8ec0c00c0c505005053b3bb3b3501111750088000050500505565005655056650509900990
00000000566556651cc11cc180088008b00bb00b89ab3c12e88ee88ec00cc00c500550053bb33bb3511711150086508005055050650550560565565009099990
00000000566556651cc11cc1800880083003300389ab3c12e88ee88ec00cc00c500550053bb33bb3517111150005656505055050650550560565565009099990
00000000565665651c1cc1c180800808c0c00c0c89ab3c12e8e88e8ec0c00c0c505005053b3bb3b3511111150805656550500505565005655056650509900990
000000005566665511cccc11880000881100001189ab3c12ee8888eecc0000cc5500005533bbbb33511111158656656555055055556556555505505509999990
000000005555555511111111888888882222222289ab3c12eeeeeeeecccccccc5555555533333333551111555656656555500555555665555550055500999900
0000000055555555111111115555555557777755599999557755555559999995577777755aaaaaa5855555585555b55555555555000000000000000000666600
000000005000000510000001508800057000077590000995777000059999999977777777a0ffff0a80888808500bbb0550000005000000000000000006666660
0000000050000005100000015086508550007705500099055777000599999999777777775aaaaaa55888888550b0b00550444405000000000000000006600660
000000005000000510000001500565655007700550099005507770059909909977077077ff0ff0ff8808808850b0b00554aaaa45000000000000000006066660
000000005000000510000001580565655007700550099005500777a59909909977077077ff0ff0ff88088088500bbb05544aa445000000000000000006066660
00000000500000051000000186566565500000055000000550007aa59999999977777777ffffffff888888885000b0b554444445000000000000000006600660
0000000050000005100000015656656550077005500990055000aaaa59099095570770755ffffff5588888855000b0b554444445000000000000000006666660
000000005555555511111111555555555557755555599555555555aa595995955757757555ffff5555888855555bbb5555555555000000000000000000666600
00000000000888000008880090988800000888000007770000077700000111000001110000000000000000000000000000777700007777000007700000aaaa00
00000000008888800088888090988880909888800077777000777770001111100011111000000000000000000000000007c77c7007000070070000700aaaaaa0
0000000008f1f1f008f1f1f0098a8a80909a8a80077070700770707001181810011818100000000000000000000000007c7777c700077000000000000aa00aa0
0000000008fffff008fffff00988888009888880077777700777777001111110011111100000000000000000000000007777777770000007000000000a0aaaa0
00000000011111100111111009222220092222200077770000777700001111000f1111f00000000000000000000000007777777770077007700000070a0aaaa0
000000000f1111f00f1111f0092222800922228007077070070770700f1111f000111100000000000000000000000000c777777c00000000000000000aa00aa0
0000000000cccc0000cccc000088880009888800007777000077770001111110011111100000000000000000000000000c7cc7c007077070070000700aaaaaa0
0000000000c0000000000c0000800000000008000070000000000700111111110111111000000000000000000000000000700700007007000007700000aaaa00
00000000000888000008880000888800000aaaa000aaaa0000111100000000000000000000000000000000000000000000000000000000000000000000000007
000000000088888000888880089999800aaa000a0aaaaaa001cccc10000000000000000000000000000000000000000000000000000000000000000000000007
00000000088888800888888089999998aaa000000aa00aa01cccccc1000000000000000000000000000000000000000000000000000000000000000000111170
00000000088888800888888089977998aa000000aa0000aa1cc77cc1000000000000000000000000000000000000000000000000000000000000000001171110
00000000011111100111111089977998aa000000a000000a1cc77cc1000000000000000000000000000000000000000000000000000000000000000001711110
000000000f1111f00f1111f089999998aaa00000a000000a1cccccc1000000000000000000000000000000000000000000000000000000000000000001111110
0000000000cccc0000cccc00089999800aaa000aa000000a01cccc10000000000000000000000000000000000000000000000000000000000000000001111110
0000000000000c0000c0000000888800000aaaa00a0000a000111100000000000000000000000000000000000000000000000000000000000000000000111100
00222ccc0088899900222cc0005556600088899000333bb000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022cc200088998002c2cccc056566660898999903b3bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
0022cccc008899990222cccc05556666088899990333bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
0022cc200088998022022cc0550556608808899033033bb000000000000000000000000000000000000000000000000000000000000000000000000000000000
0022cccc008899990022222000555550008888800033333000000000000000000000000000000000000000000000000000000000000000000000000000000000
02222c22088889882222000255550005888800083333000300000000000000000000000000000000000000000000000000000000000000000000000000000000
02222222088888880220020005500500088008000330030000000000000000000000000000000000000000000000000000000000000000000000000000000000
22220022888800880022202000555050008880800033303000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888888888888888888888888888888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087777777777777777777777777777778
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087888888888888888888888888888878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087878888888888888888888888888878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087877888888888888888888888888878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087877888888888888888888888887878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087887788888888888888888888887878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087877778888888888888888888877878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087887778888888888888888887777878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087887877888888888888888877778878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087888777788888888888878777888878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087888878778888888888787778777878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087888887777888888888777777788878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087888888877787778877777777887878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087888888887777777777777777778878
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087888888777777777777777777888878
00000000000000000000000000000000000000000000000000000000000000008777777777777777777777777777777887888887777777777777777788778878
00000000000000000000000000000000000000000000000000000000000000008777777777777777777777777777777887888877777777777777777777777878
00000000000000000000000000000000000000000000000000000000000000008777777778887788877888777777777887888877777777777777777777788878
00000000000000000000000000000000000000000000000000000000000000008777777778787787877877777777777887888788787777777777777777777878
00000000000000000000000000000000000000000000000000000000000000008777777778877787877877777777777887888887888777777777777778788878
00000000000000000000000000000000000000000000000000000000000000008777777778787787877877777777777887888888888877777777878787888878
00000000000000000000000000000000000000000000000000000000000000008777777778787788877888777777777887888888888877777777788888888878
00000000000000000000000000000000000000000000000000000000000000008777777777777777777777777777777887888888888877777777888888888878
00000000000000000000000000000000000000000000000000000000000000008777777777777777777777777777777887888888888777777777888888888878
00000000000000000000000000000000000000000000000000000000000000008778887888787878877888788878887887888887788777777778888888888878
00000000000000000000000000000000000000000000000000000000000000008778777787787878787787787878777887888877787777777777788888888878
00000000000000000000000000000000000000000000000000000000000000008778887787787878787787787878887887888788777777777777788888888878
00000000000000000000000000000000000000000000000000000000000000008777787787787878787787787877787887888888878887777777778888888878
00000000000000000000000000000000000000000000000000000000000000008778887787788878877888788878887887888888878877777777777888888878
00000000000000000000000000000000000000000000000000000000000000008777777777777777777777777777777887888888788877788877777788888878
00000000000000000000000000000000000000000000000000000000000000008888888888888888888888888888888887888888888888888888887788888878
__gff__
0001010101010101010105040202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001d0501805014050110500d05009050070500305001050240002300022000200001f0001d0001c0001c0001a000190001800016000150001400013000120001100011000100000f0000e0000c0000a000
00010000203501a35016350113500d35007350033500135000300023000e300093000230000300063000330002300343001a3001a3001b3001b3001b2001b2000620008200072000670005200042000350003500
000100001675018750197501b7501c7501e750207502375025750277502b7502e750347503d7502070002700007002c70027700227001e7001d70000000000000000000000000000000000000000000000000000
004000153a7651b200337453a70538755327052c73533705387051b7253670524735247052c745377053375500705387651b7053a7052b7052b705247052470536705367052c7052c70500005000050000500005
008000100c7440000400004000040d7540000400004000041c7640000400000000002b77400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100002a6512a6512a651266512665126651276512965127651246511f6511f6511f6512165122651216511e6511b6511a6511b6511c6511c6511a65116651126510f6510e6510e6510d6510b6510765105651
002900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 06034344

