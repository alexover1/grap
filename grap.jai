#import "Basic";
#import "File";
#import "String";
#import "File_Utilities";
#import "Command_Line";
#import "Text_File_Handler";
#import "Print_Color";

main :: () {
    Arguments :: struct {
        i: bool; @"?Case insensitive search."
    }

    success, args, is_set, free_args := parse_arguments(Arguments);
    if !success return;

    if free_args.count == {
      case 1;
      case 2;
      case;
        log_error("Usage: grap [options] search_pattern (file_pattern)\n");

        if free_args.count > 2 {
            log_error("Too many arguments were provided. (Wanted at most 2, but got %).\n", free_args.count);
        } else {
            log_error("Not enough arguments were provided. (Wanted at most 2, but got %). A string to search for must be the first argument to the program.\n", free_args.count);
        }
        return;
    }

    User_Data :: struct {
        search_pattern: string;
        file_pattern := "*";

        string_contains := #procedure_of_call contains("Hello, Sailor!", "Sailor");
        string_index_of := #procedure_of_call find_index_from_left("Goodbye, Seaman.", "Seaman");
    }

    user_data: User_Data;
    user_data.search_pattern = free_args[0];

    if args.i {
        user_data.string_contains = contains_nocase;
        user_data.string_index_of = find_index_from_left_nocase;
    }

    if free_args.count == 2 {
        user_data.file_pattern = free_args[1];
    }

    visit_files(".", true, *user_data, (info, user_data) => {
        using user_data;

        // TODO(alex): The wildcard matching only works on the file name, not the path.
        // Which means you can't do something like `grap "dot ::" MyMath2/*`, which we may
        // want to be able to do in the future...

        // Match simple wildcard patterns. Supports: `*`, `?`, `[]` and `[-]` only.
        // @@ There's no support for `+`, `(|)`, `[^]`
        if !wildcard_match(info.short_name, file_pattern) return;

        handler: Text_File_Handler;
        handler.do_version_number = false;
        handler.strip_comments_from_ends_of_lines = false;

        defer deinit(*handler);

        start_file(*handler, info.short_name, info.full_name, false);
        if handler.failed return;

        while true {
            line, found := consume_next_line(*handler);
            if !found break;

            if contains(line, 0) {
                break;
            }

            found = string_contains(line, search_pattern);
            if found {
                print("%:%: ", info.full_name, handler.line_number);

                while line.count {
                    index := find_index_from_left(line, search_pattern);
                    if index != -1 {
                        print_color("%", slice(line, 0, index), color = LINE_COLOR);
                        print_color("%", search_pattern, color = HIGHLIGHT_COLOR);
                        advance(*line, index + search_pattern.count);
                    } else {
                        print_color("%", line, color = LINE_COLOR);
                        advance(*line, line.count);
                    }
                }

                print("\n");
            }
        }
    });
}

// Console display colors
LINE_COLOR :: Console_Color.HI_CYAN;
HIGHLIGHT_COLOR :: Console_Color.HI_RED;


find_index_from_left_nocase :: (s: string, substring: string, start_index := 0) -> s64 {
    if !substring return -1;

    // This is SO SLOW! @Cleanup.
    for i: start_index..s.count-substring.count {
        t := slice(s, i, substring.count);
        if equal_nocase(t, substring) return i;
    }

    return -1;
}
