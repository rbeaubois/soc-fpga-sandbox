namespace eval futils {
    # Parse a generic from VHDL file
    # 
    # Parameters:
    #   - fpath_vhdl: Path to file to parse (str).
    #   - label: The second number (str).
    # 
    # Returns:
    #   - The generic value (int, float, or str).
    #
    # Example:
    #   parse_vhdl_generic ./test.vhd DWIDTH_FIFO => 1024
    #
    proc parse_vhdl_generic {fpath_vhdl label} {
        # Expression matching is:
        #
        # {^\s*(constant)\s+(\S+)\s*:\s*(\S+)\s*:=\s*(\S+)\s*;\s*$}
        # - ^\s*(constant) matches the constant keyword at the beginning of the line, with optional leading spaces.
        # - (\S+) captures the constant name (name), which is a non-whitespace sequence.
        # - \s*:\s* matches the colon (:) and any spaces around it.
        # - (\S+) captures the type (type).
        # - \s*:=\s* matches the assignment operator (:=) and any surrounding spaces.
        # - (\S+) captures the assigned value (value).
        # - \s*;\s*$ matches the closing semicolon (;) with optional trailing spaces.

        # Check if file exists
        if { ![file exists $fpath_vhdl] } {
            error "$fpath_vhdl does not exist."
        }

        # Read file content
        catch {set fptr [open $fpath_vhdl r]}
        set contents [read -nonewline $fptr]
        close $fptr

        # Split contents by new line
        set splitCont [split $contents "\n"]

        # Iterate lines to find matching definition
        foreach ele $splitCont {
            # Parse constant definitions
            if {[regexp {^\s*(constant)\s+(\S+)\s*:\s*(\S+)\s*:=\s*(\S+)\s*;\s*$} $ele -> keyword name type value]} {
                # Check if constant name matches
                if { $name eq $label } {
                    # Remove underscores (for integers written as 100_000)
                    # regsub {_} $value "" value; # only subsitute first match
                    set value [string map {"_" ""} $value]

                    # Determine type (int, float, or string)
                    if {[regexp {^\d+$} $value]} {
                        return [expr {$value}]; # (integer)
                    } elseif {[regexp {^\d+\.\d+$} $value]} {
                        return [expr {$value}]; # (float)
                    } elseif {[regexp {^".*"$} $value]} {
                        return [string range $value 1 end-1]; # (str)
                    } else {
                        puts "Match found but type is not supported (supported are: int,float,str)."
                        return -1; # others type not handled
                    }
                }
            }
        }

        # Return -1 if label is not found
        return -1
    }

    # Find files in folder and subfolders
    # 
    # Parameters:
    #   - directory: Path to directory (str).
    #   - pattern: File extension filter: *.vhd, *.xdc (str).
    # 
    # Returns:
    #   - List of files (list str).
    #
    # Example:
    #   find_files ./src *.vhd => ["/rootpath/src/top.vhd" "/rootpath/src/common.vhd"]
    #
    proc find_files {directory pattern} {

        # Fix the directory name, this ensures the directory name is in the
        # native format for the platform and contains a final directory seperator
        set directory [string trimright [file join [file normalize $directory] { }]]

        # Starting with the passed in directory, do a breadth first search for
        # subdirectories. Avoid cycles by normalizing all file paths and checking
        # for duplicates at each level.

        set directories [list $directory]
        set parents $directory
        while {[llength $parents] > 0} {

            # Find all the children at the current level
            set children [list]
            foreach parent $parents {
                set children [concat $children [glob -nocomplain -type {d r} -path $parent *]]
            }

            # Normalize the children
            set length [llength $children]
            for {set i 0} {$i < $length} {incr i} {
                lset children $i [string trimright [file join [file normalize [lindex $children $i]] { }]]
            }

            # Make the list of children unique
            set children [lsort -unique $children]

            # Find the children that are not duplicates, use them for the next level
            set parents [list]
            foreach child $children {
                if {[lsearch -sorted $directories $child] == -1} {
                    lappend parents $child
                }
            }

            # Append the next level directories to the complete list
            set directories [lsort -unique [concat $directories $parents]]
        }

        # Get all the files in the passed in directory and all its subdirectories
        set result [list]
        foreach directory $directories {
            set result [concat $result [glob -nocomplain -type {f r} -path $directory -- $pattern]]
        }

        # Normalize the filenames
        set length [llength $result]
        for {set i 0} {$i < $length} {incr i} {
            lset result $i [file normalize [lindex $result $i]]
        }

        # Return only unique filenames
        return [lsort -unique $result]
    }
}