(Untitled) Roguelike ver 0.4.0

Copyright © 2019 Elias Mote
Copyright © 2019 Roc Studios

I. Disclaimer
II. Version History
III. Requirements
IV. Story
V. Controls
VI. Contact
VII. Credits

I. Disclaimer

This software may be not be reproduced under any circumstances except for personal, private use. It may
not be placed on any web site or otherwise distributed publicly except at the sole discretion of the 
author. Placement of this readme or game on any other web site or as a part of any public display is
strictly prohibited, and a violation of copyright.

II. Version History

------------------------
V0.4.0 - Current version
------------------------
------------------------------------------------- Updates -----------------------------------------------
- Added power-up sprites for movement speed, status shots (fire, ice, poison, stone)
- Created stats screen
- Treasure rooms created! Treasures such as powerups will be randomly selected from an available pool.
- Ice shot powerup can be found in a treasure room. The shot will occasionally shoot ice shots depending
on the player's current luck stat.
- Ice shots will slow enemies down.
- Enemies are given real health values now instead of dying in one hit from anything.
- Players and enemies are given temporary invincibility after being hit.

------------------------
V0.3.0
------------------------
------------------------------------------------- Updates -----------------------------------------------
- Bombs are now in the game! Press the 'x' key to drop them. They can be used to blow up walls to secret
rooms and damage enemies. Enemies also currently always drop a bomb.
- Shops are now available. For the time being, shops have 3 bombs that each cost 3 coins each.
- Coins are now fully working! There are pennies, nickels and dimes. Secret rooms currently have 4
pennies, while super secret rooms have 4 nickels.
- Some changes to enemies:
-- Skeletons are present which shoot ice balls that slow the player temporarily.
-- Mages shoot crescent magic which travels through walls (may change this to status effect instead).
- The map and minimap have been changed so that they reveal diagonally adjacent rooms as well.
- When defeated, the game asks if the player wants to restart the game using the 'x' key.
- Map size has been toned down

------------------------------------------------ Bug fixes ----------------------------------------------
- Enemies will no longer appear in solid blocks

------------------------
V0.2.0
------------------------

------------------------------------------------- Updates -----------------------------------------------

-- Refactored code, including adding some event driven programming. Eventual goal is to reduce the number
of global variables, decouple functions and improve encapsulation.
-- Updated the look of the secret and super secret rooms.
-- Added some sprites, including money and the icon for the shop.
-- Added some sfx.
-- Added a minimap.
-- Map now only shows rooms visited as well as rooms adjacent (this is temporary to the current room).
-- Added a teleporter in the boss room that goes to the next floor.
-- There is a bug with collision detection with the left and right side of the room (in the doorways). The
bug is still there, but I reduced the distance for when the player moves to the next room to hide this bug.
-- Player will lose health and die when attacked.
-- Added coin pickup.
-- Added number of coins to player HUD.
-- Fixed the get_room_connections function so that validation can work properly.

------------------------
V0.1.2
------------------------
- Added random enemy generation
- Added a demon enemy that shoots fireballs in 4 directions
- Enemies can be killed permanently
- Blood particles from enemy death
- Added character animation

------------------------
V0.1.1
------------------------
- Fixed map generation so that the map creation makes more sense
- Player can shoot with 'Z'
- Enemy added
- Map added to pause menu
- Code refactored to reduce the number of global variables

------------------------
V0.1.0
------------------------
- Initial commit
- Map random generator created
- Player movement

III. Requirements


IV. Story
?????????????????

IV. Controls
- Use up, down, left, right keys to move around.
- Use the 'z' key to shoot bullets
- Use the 'x' key to drop bombs.

V. Contact
Contact me with questions or comments at rulerofchaosstudios@gmail.com
Twitter: twitter.com/Roc_Studios
Twitch:
Facebook page:
Itch.io page: rocstudios.itch.io
Game jolt page: gamejolt.com/@Roc_Studios


VI. Credits
Created by: Elias Mote
Tested by: Dred4170
Engine: Pico-8
Programming language: Lua
Music: Pico-8
Sound effects: Pico-8