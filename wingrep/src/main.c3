module wingrep;
import std::io;
import std::collections::list;
import drcli;

// Pattern selection and interpretation
const PATHS_FLAG = "-p";
const PATHS_DESC = "Paths to search for patterns.";
const PATTERN_FLAG = "-s";
const PATTERN_DESC = "Pattern for matching.";
const EXCLUDE_FLAG = "-e";
const EXCLUDE_DESC = "Paths to exclude.";

// Output control
const LINENUMBER_FLAG = "-n";
const LINENUMBER_DESC = "Print line number with output lines.";
const RECURSIVE_FLAG = "-r";
const RECURSIVE_DESC = "Search recursively.";
const FILESWITHOUTMATCH_FLAG = "-L";
const FILESWITHOUTMATCH_DESC = "Print only names of files with no matches.";
const FILESWITHMATCH_FLAG = "-l";
const FILESWITHMATCH_DESC = "Print only names of files with matches.";

const RESET          = "\x1b[0m";
const BLACK          = "\x1b[30m";
const RED            = "\x1b[31m";
const GREEN          = "\x1b[32m";
const YELLOW         = "\x1b[33m";
const BLUE           = "\x1b[34m";
const MAGENTA        = "\x1b[35m";
const CYAN           = "\x1b[36m";
const WHITE          = "\x1b[37m";
const BRIGHT_BLACK   = "\x1b[90m";
const BRIGHT_RED     = "\x1b[91m";
const BRIGHT_GREEN   = "\x1b[92m";
const BRIGHT_YELLOW  = "\x1b[93m";
const BRIGHT_BLUE    = "\x1b[94m";
const BRIGHT_MAGENTA = "\x1b[95m";
const BRIGHT_CYAN    = "\x1b[96m";
const BRIGHT_WHITE   = "\x1b[97m";

fault WingrepError {
    NO_MATCH
}

struct Line {
    String line;
    int number;
    int start;
    int end;
}

struct Match {
    String filename;
    List(<Line>) lines;
    bool matches;
}

fn void printfilename(String filename) {
    io::printf("%s%s%s", BRIGHT_MAGENTA, filename, RESET);
}

fn void printcolumn() {
    io::printf("%s:%s", BRIGHT_CYAN, RESET);
}

fn void printlinenum(int n) {
    io::printf("%s%d%s", BRIGHT_GREEN, n, RESET);
}

fn void printmatch(String line, int start, int end) {
    io::printf("%s%s%s%s%s", start != 0 ? line[..start - 1] : "", BRIGHT_RED, line[start : end], RESET, line[start + end..]);
}

fn void print(Match match, Drcli cli) {

    bool linenumber = cli.flags.contains(LINENUMBER_FLAG);
    bool fileswithoutmatch = cli.flags.contains(FILESWITHOUTMATCH_FLAG);
    bool fileswithmatch = cli.flags.contains(FILESWITHMATCH_FLAG);

    if (fileswithmatch && match.matches) {
        io::printfn("%s%s%s", BRIGHT_MAGENTA, match.filename, RESET);
    } else if (fileswithoutmatch && !match.matches) {
        io::printfn("%s%s%s", BRIGHT_MAGENTA, match.filename, RESET);
    }  else if (!fileswithoutmatch && match.matches){
        foreach (line : match.lines) {
            int start = line.start;
            int end = line.end;
            if (linenumber) {
                printfilename(match.filename);
                printcolumn();
                printlinenum(line.number);
                printcolumn();
                printmatch(line.line, line.start, line.end);
                io::printn();
            } else {
                printfilename(match.filename);
                printcolumn();
                printmatch(line.line, line.start, line.end);
                io::printn();
            }
        }        
    }
}


fn bool! isExcluded(Path path, Drcli cli) {
    if (cli.flags.contains(EXCLUDE_FLAG)) {
        Flags exclude = cli.flags.getById(EXCLUDE_FLAG)!;
        foreach (e : exclude.values) {
            if (path.str_view().contains(e)) {
                return true;
            }
        }
    }

    return false;
}

fn Line! contains(String line,  String pattern, int linenumber) {
    if (line == pattern) {
        return {
            line, linenumber, 0, line.len
        };
    }
    
    
    int start = 0;
    int end = 0;

    for (int i = 0; i < line.len; ++i) {
        int j = 0;
        int h = i;
        while (j < pattern.len && h < line.len && line[h] == pattern[j]) {
            ++j; ++h;
        }

        if (j == pattern.len) {
            start = i;
            end = j;
            break;
        }
    }

    if (end != 0) {
        return {
            line, linenumber, start, end
        };
    }

    return WingrepError.NO_MATCH?;
}

fn void! match(Path path, Drcli cli) {
    Flags patternflag = cli.flags.getById(PATTERN_FLAG)!;
   
    String! extension = path.extension();
    if (catch err = extension) {
        return;
    } 

    String bytes = (String)file::load_temp(path.str_view())!;
    String[] lines = bytes.split("\n");
    foreach(pattern : patternflag.values) {
        Match match = {path.str_view(), {}, false};

        for (int i = 0, int n = 1; i < lines.len; ++i, ++n) {
            Line! line = contains(lines[i], pattern, n);
            if (catch err = line) {
                continue;
            } 
            match.lines.push(line);
            match.matches = true; 
        }

        print(match, cli);
    }
}


fn void! pathWalker(Path path, Drcli cli) {
    PathList pathList = path::ls(path)!;

    foreach (p : pathList) {
        Path absolute = p.absolute()!;
        if (!isExcluded(absolute, cli)!) {
            if (catch err = match(absolute, cli)) {
                continue;
            }
        }
    }
}

fn bool! pathWalkerRecursive(Path path, bool is_dir, Drcli* cli) {

    if (!is_dir && !isExcluded(path, *cli)!) {
        if (catch err = match(path, *cli)) {
            return false;
        }
    }
    return false;
}

fn void! start(Drcli cli) {
    Flags path = cli.flags.getById(PATHS_FLAG)!;
    bool recursive = cli.flags.contains(RECURSIVE_FLAG);
    
    foreach (p : path.values) {
        Path! start = path::new(p);
        if (catch err = start) {
            io::eprintfn("ERROR: Failed to create path '%s': %s", p, err);
            continue;
        }
        if (recursive) {
            if (catch err = start.walk((PathWalker)&pathWalkerRecursive, &cli)) {
                io::eprintfn("ERROR: Failed to walk path recursively '%s': %s", start, err);
                continue;
            }
        } else {
            if (catch err = pathWalker(start, cli)) {
                io::eprintfn("ERROR: Failed to walk path '%s': %s", start, err);
                continue;
            }
        }
    }
}

fn void! main(String[] args)
{
    List(<Flag>) flags;
    
    Flag paths = {PATHS_FLAG, PATHS_DESC, true, true};
    Flag pattern = {PATTERN_FLAG, PATTERN_DESC, true, true};
    Flag exclude = {EXCLUDE_FLAG, EXCLUDE_DESC, false, true};
    Flag linenumber = {LINENUMBER_FLAG, LINENUMBER_DESC, false, false};
    Flag recursive = {RECURSIVE_FLAG, RECURSIVE_DESC, false, false};
    Flag fileswithoutmatch = {FILESWITHOUTMATCH_FLAG, FILESWITHOUTMATCH_DESC, false, false};
    Flag fileswithmatch = {FILESWITHMATCH_FLAG, FILESWITHMATCH_DESC, false, false};
    
    flags.push(paths);
    flags.push(pattern);
    flags.push(exclude);
    flags.push(linenumber);
    flags.push(recursive);
    flags.push(fileswithoutmatch);
    flags.push(fileswithmatch);

    Drcli cli = drcli::new(flags, args)!;

    if (catch err = start(cli)) {
        io::eprintfn("ERROR: start failed: %s", err);
    }
}
