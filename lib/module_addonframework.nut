//---------- DOCUMENTATION ----------

/**
FUNCTIONS FOR DEFINING A TREE OF SETTINGS AND READING/WRITING CONFIGS
! requires lib/module_base !
! requires lib/module_math !
! requires lib/module_tasks !
! requires lib/module_misc !
------------------------------------
I'm not going to write detailed documentation for this module, just an example:

//	perkmod <- Addonframework({
//		title = "Perkmod"
//		version = "0.0"
//		verbose = {
//			config_field = true
//			default_value = true
//		}
//		securemode = {
//			config_field = true
//			default_value = true
//		}
//		entries = [
//			Entry("Thirdperson", true, {
//				varType = "bool"
//				defaultValue = false
//				onChange = function(value, old_value, entry) {
//					say_chat("Thirdperson: " + old_value  + " -> " + value)
//				}
//			})
//		]
//		reloadCommand = "PerkmodReload"
//	})

 */

//---------- CODE ----------

this = ::root

log("[lib] including module_addonframework")

_def_constvar("buttons", BidirectionalMap([
	["none", 0],
	
	["+forward", IN_FORWARD],
	["+back", IN_BACK],
	["+moveleft", IN_MOVELEFT],
	["+moveright", IN_MOVERIGHT],
	
	["+jump", IN_JUMP],
	["+duck", IN_DUCK],
	["+speed", IN_SPEED],
	
	["+attack", IN_ATTACK],
	["+attack2", IN_ATTACK2],
	["+reload", IN_RELOAD],
	["+zoom", IN_ZOOM],
	
	["+use", IN_USE],
	
	["+alt1", IN_ALT1],
	["+alt2", IN_ALT2],
	["+score", IN_SCORE]
]))

_def_constvar("buttons_constraint", BelongsToSet(
	buttons.arrayOfStraightKeys(),
	"valid values: " + concat(buttons.arrayOfStraightKeys(), ", ")
))

DoIncludeScript("kapkan/lib/entry", this)

class Addonframework {

	_saved_constructor_params = null
	
	_chat_prefix = null
	_title = null
	_version = null
	_full_title = null
	_cfgFilename = null
	_errlogFilename = null
	_backupFilename = null
	
	_config = null
	_verbose = true
	_securemode = false
	_predefined = null
	_strings = null
	
	entries = null
	
	function addon_logf(str, ...) {
		local args = [this, str]
		args.extend(vargv)
		local message = _chat_prefix + " " + format.acall(args)
		log(message)
	}
	
	function addon_sayf(str, ...) {
		local args = [this, str]
		args.extend(vargv)
		local message = _chat_prefix + " " + format.acall(args)
		log(message)
		if (_verbose) say_chat(message)
	}
	
	constructor(params) {
		
		_saved_constructor_params = clone params
		_title = ("title" in params) ? params.title : "Unnamed"
		_version = ("version" in params) ? params.version : null
		_cfgFilename = ("cfgFilename" in params) ? params.cfgFilename : _title + "_config.txt"
		_errlogFilename = ("errlogFilename" in params) ? params.errlogFilename : _title + "_errors.txt"
		_backupFilename = ("backupFilename" in params) ? params.backupFilename : _title + "_backup.txt"
		_chat_prefix = ("chat_prefix" in params) ? params.chat_prefix : "[" + _title + "]"
		_full_title = _version ? (_title + " " + _version) : _title
		
		addon_logf("%s mod is loading", _full_title)
		
		// Trying to load config from file
		
		_config = {}
		local cfgString = file_read(_cfgFilename)
		local cfgException = null
		if (cfgString) {
			try {
				_config = compilestring( "return {" + cfgString + "}" )()
			} catch (exception) {
				cfgException = exception
			}
		} else {
			addon_logf("config not found")
		}
		
		//reading predefined fields from params
		local predefined_fields = ["verbose", "securemode"]
		_predefined = {}
		foreach(field in predefined_fields) {
			_predefined[field] <- { config_field = false, default_value = true }
			if (field in params) {
				if ("config_field" in params[field]) _predefined[field].config_field = params[field].config_field
				if ("default_value" in params[field]) _predefined[field].default_value = params[field].default_value
			}
		}
		
		local verbose_in_config = _predefined.verbose.config_field && ("Verbose" in _config)
		_verbose = verbose_in_config ? _config.Verbose : _predefined.verbose.default_value
		
		local securemode_in_config = _predefined.securemode.config_field && ("SecureMode" in _config)
		_securemode = securemode_in_config ? _config.SecureMode : _predefined.securemode.default_value
		
		//default strings
		_strings = {
			config = {
				configHeader = "/////////////////////////////////////////////\n//  " + _full_title + "\n//  Config generated at: %s\n//\n// Change any values as you wish!\n// Don't change variable types.\n// Don't add or remove lines.\n// Don't add comments to this file.\n// Ask if you have any problems.\n//////////////////////////////////////////////\n\n"
				errLogHeader = _title + ", error log:\n\n"
				errLogFooter = "\nYour config file was saved as backup in this folder: %s"
				errLogNotExists = "Entry does not exist: %s"
				errLogUntouched = "Entry should be in config: %s"
				errLogWrongType = "Wrong type: entry %s should have type %s. Restored to default."
				errLogOutOfRange = "Out of range: %s, %s"
				errLogConstraint = "Invalid value for entry %s, %s"
				SecureMode = "If true, only server host and AdminSystem admins can issue commands"
				Verbose = "If true, addon will print messages in chat on startup"
			}
			chat = {
				cfgDoesNotExistWelcome = _title
					+ " mod was loaded.\nConfiguration file doesn't exist and was created:\nLeft 4 Dead 2/left4dead2/ems/%s"
				cfgExistsWelcome = _title + " mod was loaded."
				cfgException = "Error occured while loading config:\n%s"
				cfgProblems = "There were some problems when loading config. See file %s for errors"
				backupSaved = "Config was fixed, backup was saved as %s"
				noArgsRequred = "Error: this command does not accept arguments."
			}
		}
		
		//reading strings from params
		if (("strings" in params) && ("config" in params.strings))
			foreach(key, value in params.strings.config) _strings.config[key] <- value
		if (("strings" in params) && ("chat" in params.strings))	
			foreach(key, value in params.strings.chat) _strings.chat[key] <- value
		
		if (cfgException) {
			addon_sayf(_strings.chat.cfgException, cfgException)
		} else if (!cfgString) {
			addon_sayf(_strings.chat.cfgDoesNotExistWelcome, _cfgFilename)
		} else {
			addon_sayf(_strings.chat.cfgExistsWelcome)
		}
		
		//defining entries tree
		local entries_array = clone params.entries
		if (_predefined.verbose.config_field) {
			local verbose_entry = Entry("Verbose", _predefined.verbose.default_value, {
				varType = "bool"
				onChange = function(value, old_value, entry) { _verbose = value }.bindenv(this)
				comment = _strings.config.Verbose
				isFeature = false
			})
			entries_array.append(verbose_entry)
		}
		if (_predefined.securemode.config_field) {
			local securemode_entry = Entry("SecureMode", _predefined.securemode.default_value, {
				varType = "bool"
				onChange = function(value, old_value, entry) { _securemode = value }.bindenv(this)
				comment = _strings.config.SecureMode
				isFeature = false
			})
			entries_array.append(securemode_entry)
		}
		entries = Entry("root", entries_array)
		
		// trying to apply config to entries tree
		// (this will call OnChange that enables features)
		// printing warnings, saving errors to file
		
		addon_logf("INITIALIZING")

		local lastUpdateResult = entries.initializeOrUpdateFromTable(_config, {
			inConfig = "configValue"
			notInConfig = "constructorValue"
			touch = "all"
		})

		addon_logf("INITIALIZING END")
		
		local shouldWriteBackup = false
		
		if (_config) {
			if (
				lastUpdateResult.unexisting.len() > 0
				|| lastUpdateResult.untouched.len() > 0
				|| lastUpdateResult.wrong.len() > 0
			) {
				shouldWriteBackup = true
				addon_sayf(_strings.chat.cfgProblems, "ems/" + _errlogFilename)
				local str = ""
				foreach(name in lastUpdateResult.unexisting) {
					str += format(_strings.config.errLogNotExists, name) + "\n"
				}
				foreach(table in lastUpdateResult.wrong) {
					if (table.error == "type") {
						str += format(_strings.config.errLogWrongType, table.entry._name, table.entry._type) + "\n"
					} else if (table.error instanceof IntClosedInterval || table.error instanceof FloatClosedInterval) {
						str += format(_strings.config.errLogOutOfRange, table.entry._name, table.error.description()) + "\n"
					} else if (table.error instanceof Constraint) {
						str += format(_strings.config.errLogConstraint, table.entry._name, table.error.description()) + "\n"
					}
				}
				foreach(entry in lastUpdateResult.untouched) {
					str += format(_strings.config.errLogUntouched, entry.getPath()) + "\n"
				}
				StringToFile(_errlogFilename, _strings.config.errLogHeader
					+ str + format(_strings.config.errLogFooter, _backupFilename) + "\n")
			}
		}
		
		//saving config
		get_datetime( function(datetime) {
			local datetime_str = datetime.day + "." + datetime.month + "." + datetime.year
				+ " " + datetime.hours + ":" + datetime.min + ":" + datetime.sec

			if (cfgException || (cfgString && shouldWriteBackup)) {
				file_write(_backupFilename, cfgString)
				say_chat(_strings.chat.backupSaved, "ems/" + _backupFilename)
			}

			local generatedConfigString = format(_strings.config.configHeader, datetime_str) + entries.toJson({
				quotesAroungStringKey = true
				bracesFromNewLine = true
				indentSymbol = "\t"
				commentOnSameLine = false
				fillSpacesBeforeComment = 15
				noRootEntry = true
				newlineBetweenFields = true
			})
			addon_logf("generated config with %d symbols", generatedConfigString.len())

			StringToFile(_cfgFilename, generatedConfigString)
			addon_logf("saved config to file " + _cfgFilename)
		})
		
		// defining console commands
		if ("reloadCommand" in params) {
			register_chat_command(params.reloadCommand, function(player, command, args_text, args) {
				if (get_permission_level(player) < 1) return
				run_next_tick( reloadConfig.bindenv(this) )
			}, 0, 0, _strings.chat.noArgsRequred)
		}
		
		addon_logf("%s finished loading", _full_title)
		
		//constructor end
	}
	
	function get_permission_level(player) {
		local result
		if (player == server_host())
			result = 2
		else if (("AdminSystem" in root) && (player.GetNetworkIDString() in AdminSystem.Admins))
			result = 2
		else if (!_securemode)
			result = 1
		else
			result = 0
		addon_logf("Permission level for player " + player_to_str(player) + ": " + result)
		return result
	}
	
	function disableFeatures() {
		addon_logf("RESETTING ALL FEATURES...")
		entries.initializeOrUpdateFromTable(null, {
			inConfig = "defaultValue"
			notInConfig = "defaultValue"
			touch = "features"
		})
		addon_logf("ALL FEATURES RESET DO DEFAULT")
	}
	
	function reloadConfig() {
		disableFeatures()
		constructor(_saved_constructor_params)
	}
	
}