//---------- DOCUMENTATION ----------

/**
READING AND WRITING FILES
! requires lib/module_base !
This module works with left4dead2/ems directory and subdirectories. There may be problems with large files.
------------------------------------
file_read(filename)
	Reads file, returns string or null. Same as FileToString.
------------------------------------
file_write(filename, str)
	Writes string to file, creates if not exist. Same as StringToFile.
------------------------------------
file_to_func(filename)
	Reads file, compiles script from it's contents, returns function or null. Uses compilestring() squirrel function.
------------------------------------
file_append(filename, str)
	Appends string to the end of file.
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_files")

file_read <- FileToString; //gets filename, returns string

file_write <- function(file, str) {
	if (str == null) throw "trying to write null to file"
	StringToFile(file, str)
}

file_to_func <- function(filename) {
	local str = FileToString(filename);
	if (!str) return null;
	return compilestring(str);
}

file_append <- function(filename, str) {
	if (str == null) throw "trying to write null to file"
	local str_from_file = FileToString(filename);
	StringToFile(filename, str_from_file ? str_from_file + str : str);
}