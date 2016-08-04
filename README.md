#(WIP) Minetest Portals (a la Stargate)



By: Harrierjack based on [technic/stargate] (https://github.com/minetest-technic/stargate)
(I admit the formspec is just a near straight copy but in my defense it looked way better then anything I could come up with :P)


Same goes for DHD textures: 'borrowed' from [DS-minetest] (https://forum.minetest.net/viewtopic.php?f=9&t=9632)


##Stargate-like portals for Minetest.


The portal itself is a structure you have to build yourself (atm anyway), it should look like this and be made from carbon steel blocks

![alt screenie] (https://raw.githubusercontent.com/harrierjack/portal_mgc/master/screenshot.png)


Then put down a DialHomeDevice (DHD) near a portal to have it connect to that portal. Right clicking the DHD will open the menu. Note that the DHD needs technic HV power for the portal to function. The DHD and the portal work wireless (let's go with that ;) )


Portals can be public or private to grant or deny access and after registering with a DHD that player becomes the owner and is the only one who can remove the portal.

All public portals are connected (no discovery necessary)

Requires:  
[Technic](https://github.com/minetest-technic/technic)


####TODO:
	- [ ] teleport
	- [ ] all directions including on its face
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

