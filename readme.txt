(Untitled) Roguelike ver 0.2.0

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
V0.2.0 - Current version
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

V. Contact
Contact me with questions or comments at rulerofchaosstudios@gmail.com
Twitter: twitter.com/Roc_Studios
Twitch:
Facebook page:
Itch.io page: rocstudios.itch.io
Game jolt page: gamejolt.com/@Roc_Studios


VI. Credits
Created by: Elias Mote
Tested by:
Engine: Pico-8
Programming language: Lua
Music: Pico-8
Sound effects: Pico-8