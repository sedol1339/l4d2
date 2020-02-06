/**
 * This data model, although it's not so simple, solves the following problems
 * - Resolves the situation when 1) user modifies it 2) we have to add new settings due to update
 * - Resolves the situation with corrupted configs, configs with unknown or missing entries
 * - Allows reloading config during the game (it's a bad idea to requre a map restart on config reload)
 * - Gives a possibility to change config with chat commands or console commands, if players can
 * - Keeps row order during config auto-generation, if we intend to to auto-generate config
 * 
 * Overall it's just a tree that keeps branch order and allows callbacks on leaf/branch changes
 * It also checks var types and limits, allows to generate squirrel-readable
 * json configs (Entry.toJson()) and stores comments to put into generated configs
 * 
 * entry is considered non-leaf in constructor when all these statements are true:
 * - entry_value is array
 * - entry_value length is non-zero
 * - entry_value[0] is Entry
 * 
 * entry params:
 * varType - type for variable, when we set entry it will try to convert types, if cannot convert - sets to default value
 * constraint - instance of Constraint class to check value (see kapkan/lib/module_misc for class definition)
 * defaultValue - such value when we don't need to do anything with game, for example for ChargerSteering.enabled it's false
 * 		if defaultValue is not set (or null), onChange will be always called on initializing!
 * onChange - function to call when value changes or entry is initialized
 * 		params: value, old_value, entry, whatWasChanged = null. See code for details.
 *		value != old_value always. When initialized, old_value == defaultValue
 * enumTableForPrint - array of strings: when auto-generating json, converts value to enumTableForPrint[value] (for constants)
 * comment - comment string for displaying in auto-generated json
 * 
 * for non-leaf entries only these params are supported: onChange, comment
 *
 */

class Entry {

	_name = null
	_isLeaf = true //this means has no childen and has value
	_value = null
	_children = null
	_childrenDict = null
	_parent = null
	_comment = null
	_onChange = null
	_constructorValue = null
	_defaultValue = null
	_type = null
	_constraint = null
	_enumTableForPrint = null
	_initialized = false
	_locked = false
	_feature = true
	
	function entry_debug_printf(...) {
		if (!debug()) return
		print("[EntryDebug] ")
		local args = [this]
		args.extend(vargv)
		local message = format.acall(args)
		printl(message)
	}
	
	function entry_debug_printf_nolinebreak(...) {
		if (!debug()) return
		print("[EntryDebug] ")
		local args = [this]
		args.extend(vargv)
		local message = format.acall(args)
		print(message)
	}
	
	function entry_debug_printf_append(...) {
		if (!debug()) return
		local args = [this]
		args.extend(vargv)
		local message = format.acall(args)
		print(message)
	}
	
	constructor(entry_name, entry_value, entry_params = null) {
		if (typeof entry_name != "string") throw "entry name should be string"
		if (has_special_symbols(entry_name)) throw "entry name cannot contain special symbols"
		if (entry_name.len() == 0) throw "entry name length should not be zero"
		_name = entry_name
		if (
			typeof entry_value == "array"
			&& entry_value.len() > 0
			&& typeof entry_value[0] == "Entry"
		) {
			_isLeaf = false
			_initialized = true //there's no point of initializing in non-leaf entries
			_children = entry_value
			_childrenDict = {}
			foreach (child in _children) {
				child._parent = this
				if (child._name in _childrenDict)
					throw format("duplicate child name %s for entry %s", child._name, _name)
				_childrenDict[child._name] <- child
			}
		} else {
			_isLeaf = true
			_value = entry_value
			_constructorValue = entry_value
		}
		if ("defaultValue" in entry_params) {
			if (!_isLeaf) throw "cannot set defaultValue for non-leaf entry " + _name
			_defaultValue = entry_params.defaultValue
		}
		if ("comment" in entry_params) {
			_comment = entry_params.comment
			if (_comment.find("\r") != null || _comment.find("\n") != null)
				throw "linebreaks in comment are not supported"
		}
		if ("onChange" in entry_params) {
			_onChange = entry_params.onChange
		}
		if ("constraint" in entry_params) {
			if (!_isLeaf) throw "cannot set constraint for non-leaf entry " + _name
			_constraint = entry_params.constraint
		}
		if ("varType" in entry_params) {
			if (!_isLeaf) throw "cannot set varType for non-leaf entry " + _name
			_type = entry_params.varType
		}
		if ("enumTableForPrint" in entry_params) {
			if (!_isLeaf) throw "cannot set enumTableForPrint for non-leaf entry " + _name
			_enumTableForPrint = entry_params.enumTableForPrint
		}
		if ("isFeature" in entry_params) {
			_feature = entry_params.isFeature
		}
		//logging
		local entry_value_str = (entry_value == null) ? "null" : entry_value.tostring()
		local entry_defaultValue_str = (_defaultValue == null) ? "null" : _defaultValue.tostring()
		entry_debug_printf(
			"entry \"%s\" created (%s) %s",
			_name,
			(_isLeaf ? "leaf" : _children.len() + " child entries"),
			(!_isLeaf ? "" : format("[value = %s, default = %s]", entry_value_str, entry_defaultValue_str))
		)
	}
	
	function _typeof() {
		return "Entry"
	}
	
	//for iteration with foreach loop
	function _nexti(prev_index) { //prev_index is null on iteration start
		if (prev_index == null) return 0
		if (prev_index >= _children.len() - 1) return null
		return prev_index + 1
	}
	
	//for iteration with foreach loop
	function _get(index) {
		try {
			if (typeof index == "string") return get(index)
			return _children[index]
		} catch (exception) {
			throw null //according to documentation
		}
	}
	
	//for manual calling
	function isLeaf() {
		return _isLeaf
	}
	
	function get(child_name = null) {
		if (child_name == null) {
			if (!_initialized) throw "cannot get(): not initialized"
			return _value
		}
		return _childrenDict[child_name]
	}
	
	function onChange(func) {
		_onChange = func
	}
	
	//for updating
	function _set(index, value) {
		local entry = _get(index) //throws null according to documentation
		entry.set(value)
	}
	
	//returns table:
	//table.result is "success", "non-leaf", "type", "constraint"
	//(in this case table.constraint is a constraint)
	function set(value) { 
		local old_value = _initialized ? _value : _defaultValue
		entry_debug_printf_nolinebreak(
			"Set <%s> %s -> %s",
			getPath(),
			(old_value == null) ? "null" : old_value.tostring(),
			(value == null) ? "null" : value.tostring()
		)
		if (!_isLeaf) {
			entry_debug_printf_append("\n") //linebreak
			logf("warning! only leaf entries can be set, cannot set entry %s", _name)
			return {
				result = "non-leaf"
			}
		}
		if (_locked) {
			entry_debug_printf_append("\n") //linebreak
			throw "trying to set locked entry; it's being modified currently"
		}
		_locked = true
		local shouldCallOnChange = false
		if (value != null && _type && typeof value != _type) {
			local cannotConvert = false
			switch(_type) {
				case "float":
					try { value = value.tofloat() } catch (exception) { cannotConvert = true }
					break;
				case "integer":
					try { value = value.tointeger() } catch (exception) { cannotConvert = true }
					break;
				case "string":
					try { value = value.tostring() } catch (exception) { cannotConvert = true }
					break;
				default:
					cannotConvert = true
			}
			if (cannotConvert) {
				entry_debug_printf_append("\n") //linebreak
				logf("warning! cannot convert %s to %s when trying to set entry %s", typeof value, _type.tostring(), _name)
				_locked = false
				return {
					result = "type"
				}
			}
		}
		if (value != null && _constraint && !_constraint(value)) {
			entry_debug_printf_append("\n") //linebreak
			logf("warning! constraint violation when trying to set entry %s: %s", _name, _constraint.description())
			_locked = false
			return {
				result = "constraint"
				constraint = _constraint
			}
		}
		local initialization = false
		if (_initialized) {
			shouldCallOnChange = (value != _value)
		} else {
			_initialized = true
			initialization = true
			entry_debug_printf_append(" [init]")
			shouldCallOnChange = (_defaultValue == null || value != _defaultValue)
		}
		_value = value
		entry_debug_printf_append("\n") //linebreak
		if (shouldCallOnChange) {
			if (_onChange) {
				entry_debug_printf("onChange at " + _name)
				local args = [root, _value, old_value, this]
				//running _onChange in root table scope without override a scope that it is binded to
				_onChange.acall(args)
			} else {
				local onChangeCalled = false
				local whatWasChanged = _name
				for(local parentEntry = _parent; parentEntry != null; parentEntry = parentEntry._parent) {
					if (parentEntry._onChange) {
						entry_debug_printf("onChange at " + parentEntry._name)
						local args = [root, _value, old_value, parentEntry, whatWasChanged]
						parentEntry.acall(args)
						onChangeCalled = true
						break
					}
					whatWasChanged = parentEntry._name + "." + whatWasChanged
				}
				if (!onChangeCalled) {
					entry_debug_printf("no onChange for entry or parents")
				}
			}
		}
		_locked = false
		return {
			result = "success"
		}
	}
	
	//for manual calling
	function contains(child_name) {
		return (child_name in _childrenDict)
	}
	
	function list() {
		if (_isLeaf)
			throw format("cannot get child list for leaf entry %s", _name)
		local list = []
		foreach (child in _children) //keep order
			list.push(child._name)
		return list
	}
	
	function toJson(_params) {
		local params = {
			quotesAroungStringKey = true
			bracesFromNewLine = true
			indentSymbol = "\t"
			commentOnSameLine = true
			fillSpacesBeforeComment = 40
			noRootEntry = false
			newlineBetweenFields = false
		}
		foreach(key, value in _params) params[key] <- value
		return _toJson(
			params.quotesAroungStringKey,
			params.bracesFromNewLine,
			params.indentSymbol,
			params.commentOnSameLine,
			params.fillSpacesBeforeComment,
			params.noRootEntry,
			params.newlineBetweenFields,
			0
		)
	}
	
	function _toJson(
		quotesAroungStringKey,
		bracesFromNewLine,
		indentSymbol,
		commentOnSameLine,	//todo
		fillSpacesBeforeComment,	//todo
		noRootEntry,
		newlineBetweenFields,
		nestingLevel
	) {
		local function varToJson(var, bracesFromNewLine, indentSymbol, nestingLevel) {
			//no indent for first line!
			local indent = ""
			for (local i = 0; i < nestingLevel; i++) indent += indentSymbol
			local vartype = typeof var
			if (vartype == "string") {
				if (!is_json_printable(var))
					return "\"\" /* CANNOT SAVE AS JSON: SPECIAL SYMBOLS IN STRING */"
				else
					return "\"" + var + "\""
			} else if (vartype == "array") {
				if (var.len() == 0) return "[]"
				local str = "[\n"
				foreach (value in var) {
					str += indent + indentSymbol + varToJson(value, bracesFromNewLine, indentSymbol, nestingLevel + 1) + ",\n"
				}
				str += "\n" + indent + "]"
			} else if (vartype == "table") {
				if (var.len() == 0) return "{}"
				local str = "{\n"
				foreach (key, value in var) {
					str += indent + indentSymbol
					if (typeof key != "string")
						str += "/* CANNOT SAVE NON-STRING KEYS AS JSON */\n"
					else if (!is_json_printable(key))
						str += "/* CANNOT SAVE AS JSON: SPECIAL SYMBOLS IN STRING */\n"
					else {
						if (quotesAroungStringKey)
							str += "\"" + key.tostring() + "\": "
						else
							str += key.tostring() + ": "
						if (bracesFromNewLine && (typeof value == "array" || typeof value == "table") && value.len() > 0)
							str += "\n" + indent + indentSymbol
						str += varToJson(value, bracesFromNewLine, indentSymbol, nestingLevel + 1) + "\n"
					}
				}
				str += indent + "}"
				return str
			} else if (vartype == "float" || vartype == "integer" || vartype == "bool") {
				return var.tostring()
			} else {
				return format("null /* CANNOT SAVE AS JSON STRING: %s */", vartype.toupper())
			}
		}
		
		local function get_spaces(n) {
			local str = ""
			for(local i = 0; i < n; i++) str += " "
			return str
		}
		
		if (!_initialized)
			log("[toJson] warning! saving not initilized entry " + _name)
		
		local indent = ""
		for (local i = 0; i < nestingLevel; i++) indent += indentSymbol
		local str = ""
		if (!noRootEntry) {
			if (_comment && !commentOnSameLine)
				str += "// " + _comment + "\n" + indent
			if (quotesAroungStringKey)
				str += "\"" + _name.tostring() + "\": "
			else
				str += _name.tostring() + ": "
		}
		if (_isLeaf) {
			if (noRootEntry) throw "trying to set noRootEntry for leaf entry"
			local multiline = false
			if (bracesFromNewLine && (typeof _value == "array" || typeof _value == "table") && _value.len() > 0)
				multiline = true
			if (multiline) {
				if (_comment && commentOnSameLine) {
					local spaces = max(fillSpacesBeforeComment - str.len(), 1)
					str += get_spaces(spaces) + "//" + _comment
				}
				str += "\n" + indent
			}
			if (_enumTableForPrint && _value in _enumTableForPrint) {
				str += _enumTableForPrint[_value]
			} else {
				str += varToJson(_value, bracesFromNewLine, indentSymbol, nestingLevel + 1)
			}
			if (!multiline && _comment && commentOnSameLine) {
				local spaces = max(fillSpacesBeforeComment - str.len(), 1)
				str += get_spaces(spaces) + "//" + _comment
			}
			str += "\n"
		} else {
			if (_comment && commentOnSameLine) {
				local spaces = max(fillSpacesBeforeComment - str.len(), 1) //1
				str += get_spaces(spaces) + "//" + _comment
			}
			if (!noRootEntry)
				str += ( bracesFromNewLine ? "\n" + indent + "{\n" : "{\n" )
			local first_child = true
			foreach (index, child_entry in _children) {
				local _indent = noRootEntry ? indent : (indent + indentSymbol)
				str += _indent
				if (!first_child && newlineBetweenFields) str += "\n" + _indent
				first_child = false
				str += child_entry._toJson(
					quotesAroungStringKey,
					bracesFromNewLine,
					indentSymbol,
					commentOnSameLine,
					fillSpacesBeforeComment,
					false,
					newlineBetweenFields,
					noRootEntry ? nestingLevel : nestingLevel + 1
				)
			}
			if (!noRootEntry)
				str += indent + "}\n"
		}
		return str
	}
	
	//returns string: full path of entry, including it's name; optionally - relative path until specified root, exclusive
	function getPath(root = null) {
		local path = _name
		for(local parentEntry = _parent; parentEntry != null; parentEntry = parentEntry._parent) {
			if (parentEntry == root) break
			path = parentEntry._name + "." + path
		}
		return path
	}
	
	/**
	 * recurrently sets using set() method
	 * checks if config has unexisting entries
	 * check if some entries were untouhed by config, using list()
	 * returns table of:
	 * - unexisting: array of entries that exist in config and doesn't exist in this entry
	 * - untouched: array of names that doesn't exist in config and exist in this entry
	 * - wrong: array of tables {entry, error}
	 */
	function initializeOrUpdateFromTable(config, _rules = null, rootEntry = null, manual_call = true) {
		local _rootEntry = rootEntry ? rootEntry : this
		local rules = _rules ? _rules : {
			inConfig = "configValue"
			notInConfig = "currentValue"
			touch = "all" //"all", "features" or "notfeatures"
			//"configValue" is a value from config (passed as param)
			//"currentValue" is a _value (for initializing)
			//"defaultValue" is a _defaultValue, when does not exist using _constructorValue
			//"constructorValue" is a _constructorValue
		}
		if (manual_call) {
			entry_debug_printf("initializeOrUpdateFromTable() rules:")
			entry_debug_printf("> inConfig = " + rules.inConfig)
			entry_debug_printf("> notInConfig = " + rules.notInConfig)
			entry_debug_printf("> touch = " + rules.touch)
		}
		//let this entry is "Upgrades"
		//config is a table: {"survivors"=..., "infected"=..., ...}
		local unexisting = []
		local untouched = []
		local wrong = []
		if (!_isLeaf) {
			foreach(name, child in _childrenDict) {
				if (name in config) {
					local result = child.initializeOrUpdateFromTable(config[name], _rules, _rootEntry, false)
					unexisting.extend(result.unexisting)
					untouched.extend(result.untouched)
					wrong.extend(result.wrong)
				} else {
					local shouldtouch = rules.touch == "all"
						|| (child._feature && rules.touch == "features")
						|| (!child._feature && rules.touch == "notfeatures")
					if (child._isLeaf && shouldtouch) {
						untouched.push(child)
						//using rules.notInConfig
						//set() performs initializing and may call onChange
						if (rules.notInConfig == "currentValue")
							child.set(child._value)
						else if (rules.notInConfig == "defaultValue")
							child.set(child._defaultValue)
						else if (rules.notInConfig == "constructorValue")
							child.set(child._constructorValue)
						else
							throw "rules.notInConfig is bad: " + rules.notInConfig.tostring()
					} else {
						local result = child.initializeOrUpdateFromTable(null, _rules, _rootEntry, false)
						untouched.extend(result.untouched)
					}
				}
			}
			local current_path = getPath(_rootEntry)
			if (config) {
				foreach(name, value in config) {
					if (!(name in _childrenDict)) {
						unexisting.push(current_path + "." + name)
					}
				}
			}
		} else {
			//leaf entry
			local shouldtouch = rules.touch == "all"
				|| (_feature && rules.touch == "features")
				|| (!_feature && rules.touch == "notfeatures")
			if (shouldtouch) {
				if (config != null) {
					local triedFromConfig = false
					local result
					if (rules.inConfig == "configValue") {
						triedFromConfig = true
						result = set(config)
					}
					if (triedFromConfig && result.result != "success") {
						wrong.push({
							entry = this
							error = result.result
							constraint = ("constraint" in result) ? result.constraint : null
						})
						if (rules.notInConfig == "currentValue")
							set(_value)
						else if (rules.notInConfig == "defaultValue")
							set(_defaultValue)
						else if (rules.notInConfig == "constructorValue")
							set(_constructorValue)
						else
							throw "rules.notInConfig is bad: " + rules.notInConfig.tostring()
					} else if (!triedFromConfig) {
						if (rules.inConfig == "currentValue")
							set(_value)
						else if (rules.inConfig == "defaultValue")
							set(_defaultValue)
						else if (rules.inConfig == "constructorValue")
							set(_constructorValue)
						else
							throw "rules.inConfig is bad: " + rules.inConfig.tostring()
					}
				} else {
					//using rules.notInConfig
					//set() performs initializing and may call onChange
					if (rules.notInConfig == "currentValue")
						set(_value)
					else if (rules.notInConfig == "defaultValue")
						set(_defaultValue ? _defaultValue : _constructorValue)
					else if (rules.notInConfig == "constructorValue")
						set(_constructorValue)
					else
						throw "rules.notInConfig is bad: " + rules.notInConfig.tostring()
				}
			}
		}
		return {
			unexisting = unexisting
			untouched = untouched
			wrong = wrong
		}
	}
	
}