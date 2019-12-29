//---------- DOCUMENTATION ----------

/**
ADDITIONAL FUNCTIONS TO WORK WITH STRINGS
! requires lib/module_base !
------------------------------------
say_chat(str, ...)
	Prints to chat for all players. If more than one argument, it uses formatting like say_chat(format(str, ...)). This function uses multiple Say() statements to print long strings. This function prints most unicode characters correctly. If you need to say something to specific team or from specific player, this function as it is is not suitable.
	Example: say_chat("Привет, %s!", playername) //in chat: "Console: Привет, kapkan!"
------------------------------------
vecstr2(vec)
	Vector to string: compact 2-digits representation. Uses "%.2f %.2f %.2f" to format vector components. Prints 0.00 instead of -0.00.
	Example: vecstr2(Ent(1).GetOrigin()) //returns "1621.00 2786.00 4.03"
------------------------------------
vecstr3(vec)
	Vector to string: compact 3-digits representation. Uses "%.3f %.3f %.3f" to format vector components. Prints 0.00 instead of -0.00.
	Example: vecstr3(Ent(1).GetOrigin()) //returns "1621.000 2786.000 4.031"
------------------------------------
tolower(str)
	Converts a string to lower case, supports english and russian symbols. If you don't need russian symbols support, use .tolower() string method.
------------------------------------
remove_quotes(str)
	If string is enclosed in quotes (first symbol is \" and last symbol is \"), removes them.
------------------------------------
has_special_symbols(str)
	Returns true if string has symbols not of A-Za-z0-9_.
------------------------------------
is_json_printable(str)
	Returns true if string is json printable (does not contain \r \n \" \\).
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_strings")

say_chat <- function(message, ...) {
	local UTF8_BYTE_1BYTE = 0
	local UTF8_BYTE_2BYTE_HEAD = 1
	local UTF8_BYTE_3BYTE_HEAD = 2
	local UTF8_BYTE_4BYTE_HEAD = 3
	local UTF8_BYTE_TAIL = 4
	local get_utf8_byte_type = function(int_char) {
		if (!(int_char & (1 << 7))) return UTF8_BYTE_1BYTE
		if (!(int_char & (1 << 6))) return UTF8_BYTE_TAIL
		if (!(int_char & (1 << 5))) return UTF8_BYTE_2BYTE_HEAD
		if (!(int_char & (1 << 4))) return UTF8_BYTE_3BYTE_HEAD
		if (!(int_char & (1 << 3))) return UTF8_BYTE_4BYTE_HEAD
	}
	local send_str_to_chat = function(str) {
		//removing whitespaces in the beginning - important!
		local last_whitespace_index = 0
		while(
			str[last_whitespace_index].tochar() == " "
			|| str[last_whitespace_index].tochar() == "\n"
			|| str[last_whitespace_index].tochar() == "\t"
		) last_whitespace_index += 1
		str = str.slice(last_whitespace_index, str.len())
		//adding char with code 1 - UTF8 characters fix
		local first_byte_type = get_utf8_byte_type(str[0])
		if (
			first_byte_type == UTF8_BYTE_2BYTE_HEAD
			|| first_byte_type == UTF8_BYTE_3BYTE_HEAD
			|| first_byte_type == UTF8_BYTE_4BYTE_HEAD
		) {
			str = (1).tochar() + str
		}
		Say(null, str, false)
	}
	local str_to_utf8_chars = function(str) {
		local arr = []
		foreach(int_char in str) {
			if (get_utf8_byte_type(int_char) == UTF8_BYTE_TAIL) {
				if (arr.len() > 0) {
					arr[arr.len() - 1] += int_char.tochar()
				}
			} else {
				arr.push(int_char.tochar())
			}
		}
		return arr
	}
	local MAX_MESSAGE_LENGTH_BYTES = 240
	local MAX_WORD_LENGTH_CHARS = 30
	//-------------------------------------
	if (typeof message != "string") {
		message = message.tostring()
	}
	if (vargv.len() > 0) {
		local args = [this, message]
		args.extend(vargv)
		message = format.acall(args)
	}
	local chars = str_to_utf8_chars(message)
	local start_index = 0
	local word_first_symbol = 0
	local current_len = 0
	while(true) {
		if (word_first_symbol >= chars.len()) {
			//log("word_first_symbol >= chars.len()")
			//printing
			local str = ""
			for (local i = start_index; i < chars.len(); i++) {
				str += chars[i]
			}
			send_str_to_chat(str)
			//log("[str len] " + str.len())
			//log(str)
			break
		}
		//seaching for end of word
		local next_space_symbol
		local word_len = chars[word_first_symbol].len()
		for(next_space_symbol = word_first_symbol + 1; next_space_symbol <= chars.len(); next_space_symbol++) {
			if (next_space_symbol == chars.len()) break
			if (next_space_symbol - word_first_symbol >= MAX_WORD_LENGTH_CHARS) break
			local char = chars[next_space_symbol]
			if (char == " ") break
			if (char == "\n") break
			if (char == "\t") break
			word_len += char.len()
		}
		local currentWordToStr = function() {
			local str = ""
			for (local i = word_first_symbol; i < next_space_symbol ;i++) {
				str += chars[i]
			}
			return str
		}
		//log("[word len] " + word_len + " [" + currentWordToStr() + "] [total len] " + (current_len + word_len))
		// start_index - first symbol that was not printed yet
		// word_first_symbol - first symbol of last word
		// next_space_symbol - first symbol after the end of last word
		// current_len - length from start_index to start of word (exclusive) in bytes
		if (current_len + word_len > MAX_MESSAGE_LENGTH_BYTES) {
			//log("current_len + word_len > MAX_MESSAGE_LENGTH_BYTES" + ": " + current_len + " + " + word_len)
			//printing without last word
			local str = ""
			for (local i = start_index; i < word_first_symbol; i++) {
				str += chars[i]
			}
			send_str_to_chat(str)
			//log("[str len] " + str.len())
			//log(str)
			start_index = word_first_symbol
			word_first_symbol = next_space_symbol
			current_len = word_len
		} else {
			word_first_symbol = next_space_symbol
			current_len += word_len
		}
	}
}

vecstr2 <- function(vec) {
	local digits = [vec.x, vec.y, vec.z]
	foreach (i, digit in digits) if (digit == -0) digits[i] = 0
	return format("%.2f %.2f %.2f", digits[0], digits[1], digits[2])
}

vecstr3 <- function(vec) {
	local digits = [vec.x, vec.y, vec.z]
	foreach (i, digit in digits) if (digit == -0) digits[i] = 0
	return format("%.3f %.3f %.3f", digits[0], digits[1], digits[2])
}

tolower <- function(str) {
	//currently supports only english and russian letters
	//extendable by this script: https://pastebin.com/26j2zJAg
	local unicode_tolower = {
		"\xFFD0\xFF90": "\xFFD0\xFFB0",
		"\xFFD0\xFF91": "\xFFD0\xFFB1",
		"\xFFD0\xFF92": "\xFFD0\xFFB2",
		"\xFFD0\xFF93": "\xFFD0\xFFB3",
		"\xFFD0\xFF94": "\xFFD0\xFFB4",
		"\xFFD0\xFF95": "\xFFD0\xFFB5",
		"\xFFD0\xFF81": "\xFFD1\xFF91",
		"\xFFD0\xFF96": "\xFFD0\xFFB6",
		"\xFFD0\xFF97": "\xFFD0\xFFB7",
		"\xFFD0\xFF98": "\xFFD0\xFFB8",
		"\xFFD0\xFF99": "\xFFD0\xFFB9",
		"\xFFD0\xFF9A": "\xFFD0\xFFBA",
		"\xFFD0\xFF9B": "\xFFD0\xFFBB",
		"\xFFD0\xFF9C": "\xFFD0\xFFBC",
		"\xFFD0\xFF9D": "\xFFD0\xFFBD",
		"\xFFD0\xFF9E": "\xFFD0\xFFBE",
		"\xFFD0\xFF9F": "\xFFD0\xFFBF",
		"\xFFD0\xFFA0": "\xFFD1\xFF80",
		"\xFFD0\xFFA1": "\xFFD1\xFF81",
		"\xFFD0\xFFA2": "\xFFD1\xFF82",
		"\xFFD0\xFFA3": "\xFFD1\xFF83",
		"\xFFD0\xFFA4": "\xFFD1\xFF84",
		"\xFFD0\xFFA5": "\xFFD1\xFF85",
		"\xFFD0\xFFA6": "\xFFD1\xFF86",
		"\xFFD0\xFFA7": "\xFFD1\xFF87",
		"\xFFD0\xFFA8": "\xFFD1\xFF88",
		"\xFFD0\xFFA9": "\xFFD1\xFF89",
		"\xFFD0\xFFAA": "\xFFD1\xFF8A",
		"\xFFD0\xFFAB": "\xFFD1\xFF8B",
		"\xFFD0\xFFAC": "\xFFD1\xFF8C",
		"\xFFD0\xFFAD": "\xFFD1\xFF8D",
		"\xFFD0\xFFAE": "\xFFD1\xFF8E",
		"\xFFD0\xFFAF": "\xFFD1\xFF8F",
	}
	//unfurtunately blobs are not supported
	str = str.tolower()
	local newstr = ""
	local has_unicode = false
	for(local i = 0; i < str.len(); i++) {
		local symbol = str[i]
		if (symbol < 0) {
			has_unicode = true
			break
		}
	}
	if (!has_unicode)
		return str
	for(local i = 0; i < str.len(); i++) {
		local symbol = str[i]
		if (symbol >= 0) {
			newstr += symbol.tochar()
		} else {
			if (i == str.len() - 1)
				throw "unfinished unicode string: last char have negative code"
			local symbol_next = str[++i]
			local unicode_char = symbol.tochar() + symbol_next.tochar()
			if (unicode_char in unicode_tolower)
				unicode_char = unicode_tolower[unicode_char]
			newstr += unicode_char
		}
	}
	return newstr
}

remove_quotes <- function(str) {
	if (str.slice(0, 1) == "\"" && str.slice(str.len() - 1) == "\"")
		return str.slice(1, str.len() - 1)
	return str
}

//[A-Za-z0-9_]
local symbolA = "A"[0]
local symbolZ = "Z"[0]
local symbola = "a"[0]
local symbolz = "z"[0]
local symbol0 = "0"[0]
local symbol9 = "9"[0]
local symbol_ = "_"[0]

has_special_symbols <- function(str) {
	foreach (char in str) {
		if (char >= symbolA && char <= symbolZ) continue
		if (char >= symbola && char <= symbolz) continue
		if (char >= symbol0 && char <= symbol9) continue
		if (char == symbol_) continue
		return true
	}
	return false
}

is_json_printable <- function(str) {
	foreach (char in str) {
		if (char.tochar() == "\r") return false
		if (char.tochar() == "\n") return false
		if (char.tochar() == "\"") return false
		if (char.tochar() == "\\") return false
	}
	return true
}