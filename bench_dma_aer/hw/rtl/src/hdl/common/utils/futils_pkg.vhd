--!	@title		File utilities
--!	@file		futils.vhd
--!	@author		Romain Beaubois
--!	@date		15 May 2024
--!	@copyright
--! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: GPL-3.0-or-later
--! 
--! @brief
--! * futils_global_pkg
--! * futils_cpp_pkg
--! 
--! @details 
--! > **15 May 2024** : file creation (RB)

-- =====
-- File utilities: global
-- =====
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

package futils_global_pkg is
    function to_uppercase(c: character) return character;
    function to_lowercase(c: character) return character;
    function to_uppercase(s: string) return string;
    function to_lowercase(s: string) return string;
    function strpad(constant strin:string; constant pad_char:character; constant size:integer) return string;
    function strrep(constant strin:string; constant char_rm:character; constant char_rep:character) return string;
end package futils_global_pkg;

-- =====
-- File utilities: C++
-- =====
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

package futils_cpp_pkg is
    procedure add_define(file fout:text; labl:string);            --! Write label and value as C define
    procedure add_define(file fout:text; labl:string; v:real);    --! Write label and value as C define
    procedure add_define(file fout:text; labl:string; v:integer); --! Write label and value as C define
    procedure add_define(file fout:text; labl:string; v:string);  --! Write label and value as C define
    procedure add_include(file fout:text; fname:string);
    procedure add_include(file fout:text; fname:string; tab:boolean);
    procedure add_pragma_ifdef(file fout:text; define:string);
    procedure add_pragma_elifdef(file fout:text; define:string);
    procedure add_pragma_else(file fout:text);
    procedure add_pragma_endif(file fout:text);
    procedure add_comment(file fout:text; msg:string);            --! Write msg as C comment
    procedure add_line(file fout:text; msg:string);               --! Write line in file
    procedure add_blank_line(file fout:text);
    procedure add_blank_line(file fout:text; nb_lines:integer);
    procedure add_include_guard_top(file fout:text; fname:string);
    procedure add_include_guard_bot(file fout:text);
end package futils_cpp_pkg;

-- =====
-- File utilities: global
-- =====
package body futils_global_pkg is
    --! Convert a character to upper case
    function to_uppercase(c: character) return character is
        variable u: character;
    begin
        case c is
            when 'a' => u := 'A';
            when 'b' => u := 'B';
            when 'c' => u := 'C';
            when 'd' => u := 'D';
            when 'e' => u := 'E';
            when 'f' => u := 'F';
            when 'g' => u := 'G';
            when 'h' => u := 'H';
            when 'i' => u := 'I';
            when 'j' => u := 'J';
            when 'k' => u := 'K';
            when 'l' => u := 'L';
            when 'm' => u := 'M';
            when 'n' => u := 'N';
            when 'o' => u := 'O';
            when 'p' => u := 'P';
            when 'q' => u := 'Q';
            when 'r' => u := 'R';
            when 's' => u := 'S';
            when 't' => u := 'T';
            when 'u' => u := 'U';
            when 'v' => u := 'V';
            when 'w' => u := 'W';
            when 'x' => u := 'X';
            when 'y' => u := 'Y';
            when 'z' => u := 'Z';
            when others => u := c;
        end case;

        return u;
    end function;

    --! convert a character to lower case
    function to_lowercase(c: character) return character is
        variable l: character;
    begin
        case c is
            when 'A' => l := 'a';
            when 'B' => l := 'b';
            when 'C' => l := 'c';
            when 'D' => l := 'd';
            when 'E' => l := 'e';
            when 'F' => l := 'f';
            when 'G' => l := 'g';
            when 'H' => l := 'h';
            when 'I' => l := 'i';
            when 'J' => l := 'j';
            when 'K' => l := 'k';
            when 'L' => l := 'l';
            when 'M' => l := 'm';
            when 'N' => l := 'n';
            when 'O' => l := 'o';
            when 'P' => l := 'p';
            when 'Q' => l := 'q';
            when 'R' => l := 'r';
            when 'S' => l := 's';
            when 'T' => l := 't';
            when 'U' => l := 'u';
            when 'V' => l := 'v';
            when 'W' => l := 'w';
            when 'X' => l := 'x';
            when 'Y' => l := 'y';
            when 'Z' => l := 'z';
            when others => l := c;
        end case;
        return l;
    end function;

    --! convert a string to upper case
    function to_uppercase(s: string) return string is
        variable uppercase: string (s'range);
    begin
        for i in s'range loop
            uppercase(i):= to_uppercase(s(i));
        end loop;
        return uppercase;
    end function;

    --! convert a string to lower case
    function to_lowercase(s: string) return string is
        variable lowercase: string (s'range);
    begin
        for i in s'range loop
            lowercase(i):= to_lowercase(s(i));
        end loop;
        return lowercase;
    end function;

    --! pad string to size
    function strpad(constant strin:string; constant pad_char:character; constant size:integer) return string is
        variable strout : string(1 to size);
    begin
        assert strin'length <= strout'length
        report "Cropped string " & strin
        severity note;

        if strin'length <= strout'length then
            for i in strout'range loop
                strout(i) := pad_char;
            end loop;
            strout(strin'range) := strin;
        else
            strout := strin(1 to size);
            report "Cropped";
        end if;
        
        return strout;
    end function;

    --! replace characters in string
    function strrep(constant strin: string; constant char_rm: character; constant char_rep: character) return string is
        variable result_str: string(1 to strin'length);
    begin
        for i in strin'range loop
            if strin(i) = char_rm then
                result_str(i) := char_rep;
            else
                result_str(i) := strin(i);
            end if;
        end loop;
    
        return result_str;
    end function;

end package body futils_global_pkg;

-- =====
-- File utilities: C++
-- =====
package body futils_cpp_pkg is
    constant KW_DEFINE  : string := "#define";
    constant KW_COMMENT : string := "//";
    constant KW_SEP_STR : string := """";
    constant KW_INCLUDE : string := "#include";
    constant TAB_SPACE  : string := "    ";

    --! Write label and value as C define from real
    procedure add_define(file fout:text; labl:string) is
        variable tmp_line   : line;
    begin
        write(tmp_line, KW_DEFINE & " " & labl);
        writeline(fout, tmp_line);
    end procedure;

    --! Write label and value as C define from real
    procedure add_define(file fout:text; labl:string; v:real) is
        variable tmp_line   : line;
    begin
        write(tmp_line, KW_DEFINE & " " & labl & " " & real'image(v));
        writeline(fout, tmp_line);
    end procedure;

    --! Write label and value as C define from integer
    procedure add_define(file fout:text; labl:string; v:integer) is
        variable tmp_line : line;
    begin
        write(tmp_line, KW_DEFINE & " " & labl & " " & integer'image(v));
        writeline(fout, tmp_line);
    end procedure;

    --! Write label and value as C define from string
    procedure add_define(file fout:text; labl:string; v:string) is
        variable tmp_line       : line;
    begin
        write(tmp_line, KW_DEFINE & " " & labl & " " & KW_SEP_STR & v & KW_SEP_STR);
        writeline(fout, tmp_line);
    end procedure;
    
    procedure add_include(file fout:text; fname:string) is
        variable tmp_line : line;
    begin
        write(tmp_line, KW_INCLUDE & " " & KW_SEP_STR & fname & ".h" & KW_SEP_STR);
        writeline(fout, tmp_line);
    end procedure;
    
    procedure add_include(file fout:text; fname:string; tab:boolean) is
        variable tmp_line : line;
    begin
        if tab then
            write(tmp_line, TAB_SPACE & KW_INCLUDE & " " & KW_SEP_STR & fname & ".h" & KW_SEP_STR);
            writeline(fout, tmp_line);
        else
            add_include(fout, fname);
        end if;
    end procedure;

    procedure add_pragma_ifdef(file fout:text; define:string) is
        variable tmp_line : line;
    begin
        write(tmp_line, "#if defined(" & define & ")");
        writeline(fout, tmp_line);
    end procedure;

    procedure add_pragma_elifdef(file fout:text; define:string) is
        variable tmp_line : line;
    begin
        write(tmp_line, "#elif defined(" & define & ")");
        writeline(fout, tmp_line);
    end procedure;

    procedure add_pragma_else(file fout:text) is
        variable tmp_line : line;
    begin
        write(tmp_line, string'("#else"));
        writeline(fout, tmp_line);
    end procedure;

    procedure add_pragma_endif(file fout:text) is
        variable tmp_line : line;
    begin
        write(tmp_line, string'("#endif"));
        writeline(fout, tmp_line);
    end procedure;


    --! Write message as C comment from string
    procedure add_comment(file fout:text; msg:string) is
        variable tmp_line   : line;
    begin
        write(tmp_line, KW_COMMENT & " " & msg);
        writeline(fout, tmp_line);
    end procedure;

    --! Write line in C file
    procedure add_line(file fout:text; msg:string) is
        variable tmp_line : line;
    begin
        write(tmp_line, msg);
        writeline(fout, tmp_line);
    end procedure;

    procedure add_blank_line(file fout:text) is
        constant blank_str  : string := "";
        variable tmp_line   : line;
    begin
        write(tmp_line, blank_str);
        writeline(fout, tmp_line);
    end procedure;

    procedure add_blank_line(file fout:text; nb_lines:integer) is
    begin
        for i in 0 to nb_lines loop
            add_blank_line(fout);
        end loop;
    end procedure;

    procedure add_include_guard_top(file fout:text; fname:string) is
        variable tmp_line1 : line;
        variable tmp_line2 : line;
    begin
        write(tmp_line1, "#ifndef __" & work.futils_global_pkg.to_uppercase(fname) & "_H__");
        write(tmp_line2, "#define __" & work.futils_global_pkg.to_uppercase(fname) & "_H__");
        writeline(fout, tmp_line1);
        writeline(fout, tmp_line2);
    end procedure;

    procedure add_include_guard_bot(file fout:text) is
        variable tmp_line : line;
    begin
        write(tmp_line, string'("#endif"));
        writeline(fout, tmp_line);
    end procedure;
end package body futils_cpp_pkg;