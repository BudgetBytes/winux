module winfind;
import std::io;
import std::collections::list;
import drcli;

const BASEDIR_FLAG = "-b";
const BASEDIR_DESC = "The starting point from where to search.";
const PATTERN_FLAG = "-p";
const PATTERN_DESC = "Pattern to search.";
const RECURSIVE_FLAG = "-r";
const RECURSIVE_DESC = "Search recursively.";

fn void! find(Path start, Drcli cli) {
    Flags patterns = cli.flags.getById(PATTERN_FLAG)!;
    bool recursive = cli.flags.contains(RECURSIVE_FLAG);

    PathList pathList = path::ls(start)!;	

    foreach (path : pathList) {
        Path absPath = start.append(path.str_view())!;

        foreach (pattern : patterns.values) {
            if (absPath.str_view().contains(pattern)) {
                io::printfn("FOUND: %s", absPath);
            }
        }

        if (path::is_dir(absPath) && recursive) {
            find(absPath, cli)!;
        }
    }
}

fn void! start(Drcli cli) {
    Flags baseDir = cli.flags.getById(BASEDIR_FLAG)!;

    foreach (b : baseDir.values) {
        Path! path = path::new(b);
        if (catch err = path) {
            io::eprintfn("ERROR: Could not get path for '%s': %s", b, err);
            continue;
        }

        Path! absolute = path.absolute();
        if (catch err = absolute) {
            io::eprintfn("ERROR: Could not get absolute path for '%s': %s", path, err);
            continue;
        }


        if (catch err = find(absolute, cli)) {
            io::eprintfn("ERROR: Error during find from '%s': %s", absolute, err);
            continue;
        }

        
    }
}

fn void! main(String[] args)
{
    List(<Flag>) flags;
    
    Flag baseDir = {BASEDIR_FLAG, BASEDIR_DESC, true, true};
    Flag pattern = {PATTERN_FLAG, PATTERN_DESC, true, true};
    Flag recursive = {RECURSIVE_FLAG, RECURSIVE_DESC, false, false};
    
    flags.push(baseDir);
    flags.push(pattern);
    flags.push(recursive);

    Drcli! cli = drcli::new(flags, args)!;

    if (catch err = start(cli)) {
        io::eprintfn("ERROR: Something went wrong during search: %s", err);
        return;
    }
}

