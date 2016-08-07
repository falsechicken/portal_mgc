#(WIP) Minetest Portals (a la Stargate)
for MineTest 0.4.14


By: Harrierjack based on [technic/stargate] (https://github.com/minetest-technic/stargate)
Formspec was a copy but eventually changed completely. Some formspec textures and gate sounds are still used (at least as placeholder)


Same goes for DHD textures: 'borrowed' from [DS-minetest] (https://forum.minetest.net/viewtopic.php?f=9&t=9632)


##Stargate-like portals for Minetest.


The portal itself is a structure you have to build yourself (atm anyway), it should look like this and be made from carbon steel blocks

![alt screenie] (https://raw.githubusercontent.com/harrierjack/portal_mgc/master/screenshot.jpg)


Then put down a DialHomeDevice (DHD) near a portal to have it connect to that portal. The portal checks where the DHD is to see which side will be used for the teleporting 'dropzone'.

Right clicking the DHD will open the menu. The portal registrator will be the owner and can change name or set private. At this time the only advantage of private is not showing up in the portal list.  
On the left bottom you can see some information about the current portal and on the right you see public portals with their address. After entering an address press the big red button and the portal activates

![alt screenie dhd] (https://raw.githubusercontent.com/harrierjack/portal_mgc/master/screenshotdhd.jpg)


After activation the portal stays open for 8 seconds, every porting entity adds to more seconds to the time it stays open.

Note that the DHD needs technic HV power for the portal to function, when the power runs out the portal shuts down (keep arms and legs inside at all times :) ). The DHD and the portal work wireless (let's go with that ;) )


![alt screenie open] (https://raw.githubusercontent.com/harrierjack/portal_mgc/master/screenshotportalon.jpg)


All public portals are connected (no discovery necessary)

Requires:  
[Technic](https://github.com/minetest-technic/technic)
__though not used yet__

####TODO:
	- [X] teleport
	- [/] all directions including on its face
	- [X] complete overhaul of DHD formspec and portal selection system
	- [ ] add technic power requirement (very high)
	- [ ] gfx
	- [ ] debug
	- [ ] code cleaning



####License:
UNLICENSE (see LICENSE file in package)
--or--
WTFPL (see below)
--or--
Whatever license you feel like. GPLv2 is nice. ;)

See also:
<http://minetest.net/>




         DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                    Version 2, December 2004

 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

 Everyone is permitted to copy and distribute verbatim or modified
 copies of this license document, and changing it is allowed as long
 as the name is changed.

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. You just DO WHAT THE FUCK YOU WANT TO.

