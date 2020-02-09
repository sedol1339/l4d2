this = getroottable()
IncludeScript("kapkan/lib/module_base")
IncludeScript("kapkan/lib/module_math")
IncludeScript("kapkan/lib/module_tasks")
IncludeScript("kapkan/lib/module_misc")
IncludeScript("kapkan/lib/module_hud") //requires module_tasks
IncludeScript("kapkan/lib/module_gamelogic") //requires module_tasks
IncludeScript("kapkan/lib/module_development") //requires module_tasks, module_strings
IncludeScript("kapkan/lib/module_botcontrol") //requires module_tasks, module_gamelogic
IncludeScript("kapkan/lib/module_serversettings") //requires module_tasks, module_gamelogic
IncludeScript("kapkan/lib/module_addonframework") //requires module_tasks
IncludeScript("kapkan/lib/module_behaviour") //requires module_tasks
lib_included <- true
//"lib_included" is not used in the library itself
//this can only be used to check if library has been already included