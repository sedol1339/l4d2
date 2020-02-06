/**
This file is used in Custom VScripts loader addon and is not meant to be used anywhere else. This is only one difference between including "lib" and "lib_auto" files. Lib_auto.nut does not injects consttable to roottable. If someone want to use this library WITHOUT Custom VScripts loader, they should include "kapkan/lib/lib", not this file.
*/

this = getroottable()
dont_add_constants_to_roottable <- true
IncludeScript("kapkan/lib/constants") //this should be executed before module_base compilation
IncludeScript("kapkan/lib/lib")