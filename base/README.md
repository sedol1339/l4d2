**Code for Custom VScripts Loader**
-------------------------------------

As an introduction I will remind that since EMS Update a lot of Left 4 Dead 2 VScripts have been released, but there's still a large problem over the scripting community. Valve didn't make a folder for auto-executing scripts, so scripters had to replace scriptedmode.nut file in their addons, which led to a poor compatibility of addons. In short:

1. Scripts are generally incompatible with each other
2. Even compatible scripts are often colored RED in addons list
3. Hooks (AllowTakeDamage and others) are not always available

I edited sm_utilities.nut, that remained untouched by all VScript addons, and added some custom code which always activates Scripted Mode (even without coop.nut, versus.nut and other stubs). But I'm not a magican and cannot create a folder for auto-executing scripts. So, links to script files should be added manually.

I'll start a detailed explanation by demonstrating script loading order in L4D2

![img](https://pp.userapi.com/c858420/v858420346/2b9e8/BJhp4TG3wDc.jpg)

