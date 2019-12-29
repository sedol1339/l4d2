//---------- DOCUMENTATION ----------

/**
MISCELLANEOUS RARELY USED FUNCTIONS
! requires lib/module_base !
------------------------------------
read_console_output(command, on_read)
	Issues specified console command and reads console output. When output is successfully read, on_read function is called. One argument is passed, which is console output string. This string should contain output of issued command, but may also contain some unrelated lines due to engine limitations. The function read_console_output() itself does not return anything.
	Under the hood this function uses vprof recording to create an empty file in ems folder, sets con_logfile to write console output to the file and FileToString function to read the file.
	Example: read_console_output("status", log) //we issue "status" console command and pass log as function that will process output string
	Output:
		Tick Number,
		rror 38
		VPROF playback finished.
		hostname: kapkan
		version : 2.1.5.5 7227 secure  
		udp/ip  : 192.168.0.7:27015 [ public n/a ]
		os      : Windows Listen
		map     : c2m2_fairgrounds at ( 1621, 2786, 66 )
		players : 1 humans, 0 bots (4 max) (not hibernating) (unreserved)

		# userid name uniqueid connected ping loss state rate adr
		#  2 1 "kapkan" STEAM_1:0:151200161  1:21:32 37 0 active 30000 loopback
		# 3 "Coach" BOT active
		# 4 "Rochelle" BOT active
		# 5 "Ellis" BOT active
		#end
------------------------------------
get_datetime(on_get)
	Gets date and time, using con_timestamp=1 and read_console_output(). When date and time are successfully read, on_get function is called. One argument is passed, which is table with fields "month", "day", "year", "hours", "min", "sec". Table also contains field "cmp_value". This is NOT a timestamp, but this can be used to compare different datetimes (cmp_value=sec+60*min+3600*hours+86400*(day-1)+86400*32*(month-1)+86400*32*12*(year-2000)).
	Example: get_datetime(logt) //this example requires logt function from kapkan/lib/strings
	Output:
		table: 
			"year": 2019
			"month": 12
			"day": 22
			"hours": 18
			"min": 27
			"sec": 7
			"cmp_value": 662668027
------------------------------------
BidirectionalMap
	Class for bidirectional map structure. List of methods:
	constructor(array) //receives array of key-value pairs
	hasStraight(key) //returns true if specified straight key exists
	hasReverse(key) //returns true if specified reverse key exists
	straight(key) //given straight key returns associated reverse key
	reverse(key) //given reverse key returns associated straight key
	arrayOfStraightKeys() //returns array of stright keys
	arrayOfReverseKeys() //returns array of reverse keys
	Example: BidirectionalMap([["one", "1"], ["two", "2"]]).reverse("2") //returns "two"
	This class still does not support adding or removing keys.
------------------------------------
Constraint
	Class that represents a constraint, for example bounds checker. List of methods:
	constructor(func) //creates a constraint from a function; function should receive any value and return boolean
	Constraint can be called as function, param is a value that we want to check.
	Example:
	local c = Constraint( @(val)(val > 0 && val < 1) )
	log( c(0) ) //false
	log( c(0.5) ) //true
	log( c(1) ) //false
IntClosedInterval
	Subclass of Constraint that represents closed integer interval. Constructor:
	IntClosedInterval(min, max)
	Example:
	local c = IntClosedInterval(-5, 5)
	log( c(0) ) //true
	log( c(5) ) //true
	log( c(6) ) //false
FloatClosedInterval
	Subclass of Constraint that represents closed floating point number interval. Constructor:
	FloatClosedInterval(min, max)
BelongsToSet
	Subclass of Constraint that represents a constraint where value should belong to set. Constructor:
	BelongsToSet(array)
	Example:
	local c = BelongsToSet(["Nick", "Ellis", "Rochelle", "Coach"])
	log( c("Nick") ) //true
	log( c("nick") ) //false
	log( c("Louis") ) //false
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_misc")

read_console_output <- function(command, on_read) {
	if ("_console_called" in root && _console_called)
		throw "console reading is in progress"
	local filename = "console"
	local con_file = format("ems/%s.csv", filename)
	local old_logfile = Convars.GetStr("con_logfile")
	if (old_logfile == con_file) old_logfile = null //probably some exception last time
	Convars.SetValue("con_logfile", con_file)
	SendToServerConsole(format("vprof_record_start ems/%s; vprof_record_stop; vprof_to_csv ems/%s", filename, filename))
	//StringToFile creates NUL-terminated file, con_logfile appends after NUL and
	//FileToString cannot read after NUL; I use vprof just to create a small text file, that's all;
	//if I create file with con_logfile, it will grow next read_console_output() calls, until it becomes too large
	//to read it with FileToString
	printl("Sending command to console: " + command)
	SendToServerConsole(command)
	EntFire("worldspawn", "CallScriptFunction", "_console_on_read")
	::_console_on_read <- function() {
		Convars.SetValue("con_logfile", old_logfile)
		local file_contents = FileToString(format("%s.csv", filename))
		_console_called = false
		on_read(file_contents) //may throw exception
	}
	::_console_called <- true
}

get_datetime <- function(on_get) {
	Convars.SetValue("con_timestamp", 1)
	read_console_output("echo", function(file_contents) {
		Convars.SetValue("con_timestamp", 0)
		try {
			local lines = split(file_contents, "\n")
			local last_line = lines[lines.len() - 1]
			local tokens = split(last_line, "/ -:")
			local table = {
				month = tokens[0].tointeger()
				day = tokens[1].tointeger()
				year = tokens[2].tointeger()
				hours = tokens[3].tointeger()
				min = tokens[4].tointeger()
				sec = tokens[5].tointeger()
			}
			table.cmp_value <- table.sec
				+ 60*table.min
				+ 3600*table.hours
				+ 86400*(table.day - 1)
				+ 86400*32*(table.month - 1)
				+ 86400*32*12*(table.year - 2000)
			on_get(table)
		} catch (exception) {
			log("Exception while getting datetime: " + exception)
			log("..file contents:")
			log(file_contents)
		}
	})
}

class BidirectionalMap {
	_dict1 = null //first -> second
	_dict2 = null //second -> first
	constructor(arr) { //should be array of pairs
		_dict1 = {}
		_dict2 = {}
		foreach(pair in arr) {
			if(pair[0] in _dict1) throw pair[0] + " is already a straight key of map"
			if(pair[1] in _dict2) throw pair[1] + " is already a reverse key of map"
			_dict1[pair[0]] <- pair[1]
			_dict2[pair[1]] <- pair[0]
		}
	}
	function hasStraight(key) {
		return (key in _dict1)
	}
	function straight(key) {
		return _dict1[key]
	}
	function hasReverse(key) {
		return (key in _dict2)
	}
	function reverse(key) {
		return _dict2[key]
	}
	function arrayOfStraightKeys() {
		local arr = []
		foreach (key, value in _dict1)
			arr.push(key)
		return arr
	}
	function arrayOfReverseKeys() {
		local arr = []
		foreach (key, value in _dict2)
			arr.push(key)
		return arr
	}
}

class Constraint {
	func = null
	_description = null
	constructor(func, _description = null) {
		this.func = func
		this._description = _description
	}
	function description() {
		if (_description) return _description
		return "No description"
	}
	function _call(scope, value) {
		return func(value)
	}
}

class IntClosedInterval extends Constraint {
	min = null
	max = null
	constructor(min, max) {
		if (min != null) this.min = min.tointeger()
		if (max != null) this.max = max.tointeger()
	}
	function description() {
		if (min != null && max != null) 
			return format("value must be between %d and %d", min, max)
		if (min != null)
			return format("value must be more than %d", min)
		if (max != null)
			return format("value must be less than %d", max)
		return "no constraint"
	}
	function _call(scope, value) {
		if (min != null && value < min) return false
		if (max != null && value > max) return false
		return true
	}
}

class FloatClosedInterval extends Constraint {
	min = null
	max = null
	constructor(min, max) {
		if (min != null) this.min = min.tofloat()
		if (max != null) this.max = max.tofloat()
	}
	function description() {
		if (min != null && max != null) 
			return format("value must be between %f and %f", min, max)
		if (min != null)
			return format("value must be more than %f", min)
		if (max != null)
			return format("value must be less than %f", max)
		return "no constraint"
	}
	function _call(scope, value) {
		if (min != null && value < min) return false
		if (max != null && value > max) return false
		return true
	}
}

class BelongsToSet extends Constraint {
	arr = null
	set = null
	constructor(arr, _description = null) {
		set = {}
		this.arr = clone arr
		foreach (value in arr) {
			if (value in set) log("warning! BelongsToSet: duplicate value " + value)
			set[value] <- true
		}
		this._description = _description
	}
	function description() {
		if (_description) return _description
		local max_len = 300
		local str = "valid values: "
		if (!arr) return str
		local first_elem = true
		foreach(value in arr) {
			local str2 = null
			try {
				str2 = value.tostring()
			} catch (exception) {
				return "valid values: <not convertable to string>"
			}
			if (str.len() + (first_elem ? 0 : 2) + str2.len() > max_len) {
				str = str + (first_elem ? "..." : ", ...")
				if (str.len() > max_len)
					str = str.slice(0, max_len - 3) + "..."
				return str
			}
			str += (first_elem ? "" : ", ") + str2
			first_elem = false
		}
		return str
	}
	function _call(scope, value) {
		return (value in set)
	}
}