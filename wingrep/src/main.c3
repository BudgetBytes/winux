module wingrep;
import std::io;
import std::collections::list;
import drcli;

// Pattern selection and interpretation
const PATHS_FLAG = "-p";
const PATHS_DESC = "Paths to search for patterns.";
const PATTERN_FLAG = "-F";
const PATTERN_DESC = "String pattern for matching.";
const REGEX_FLAG = "-e";
const REGEX_DESC = "Use regex pattern for matching.";

// Output control
const MAXCOUNT_FLAG = "-m";
const MAXCOUNT_DESC = "Stop after n matcher.";
const LINENUMBER_FLAG = "-n";
const LINENUMBER_DESC = "Print line number with output lines.";
const RECURSIVE_FLAG = "-r";
const RECURSIVE_DESC = "Search recursively.";
const FILESWITHOUTMATCH_FLAG = "-L";
const FILESWITHOUTMATCH_DESC = "Print only names of files with no matches.";
const FILESWITHMATCH_FLAG = "-l";
const FILESWITHMATCH_DESC = "Print only names of files with matches.";


fn void! main(String[] args)
{
	List(<ProgramFlag>) flags;
    
    ProgramFlag baseDir = {PATHS_FLAG, PATHS_DESC, true, true};
    ProgramFlag pattern = {PATTERN_FLAG, PATTERN_DESC, false, true};
	ProgramFlag regex = {REGEX_FLAG, REGEX_DESC, false, true};
	ProgramFlag maxcount = {MAXCOUNT_FLAG, MAXCOUNT_DESC, false, true};
	ProgramFlag linenumber = {LINENUMBER_FLAG, LINENUMBER_DESC, false, false};
    ProgramFlag recursive = {RECURSIVE_FLAG, RECURSIVE_DESC, false, false};
	ProgramFlag fileswithoutmatch = {FILESWITHOUTMATCH_FLAG, FILESWITHOUTMATCH_DESC, false, false};
	ProgramFlag fileswithmatch = {FILESWITHMATCH_FLAG, FILESWITHMATCH_DESC, false, false};
    
    flags.push(baseDir);
    flags.push(pattern);
	flags.push(regex);
	flags.push(maxcount);
	flags.push(linenumber);
    flags.push(recursive);
	flags.push(fileswithoutmatch);
	flags.push(fileswithmatch);

    Drcli! cli = drcli::new(flags, args)!;
}
