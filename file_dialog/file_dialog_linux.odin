package file_dialog

import "core:fmt"
import "core:os"
import "core:strings"

when ODIN_OS == .Linux || ODIN_OS == .Darwin {
	foreign libc 
	{
		popen :: proc(command: cstring, type: cstring) -> ^FILE ---
		pclose :: proc(stream: ^FILE) -> i32 ---
		fgets :: proc "cdecl" (s: [^]byte, n: i32, stream: ^FILE) -> [^]u8 ---
	}

	foreign import libc "system:c"
	FILE :: struct {}


	@(private = "file")
	DialogType :: enum {
		Zenity,
		KDialog,
	}

	@(private = "file")
	find_installed_dialog_binary :: proc() -> (path: string, type: DialogType, ok: bool) {

		zenity := find_binary_location("zenity")
		kdialog := find_binary_location("kdialog")

		desktop := os.get_env("XDG_CURRENT_DESKTOP", context.temp_allocator)
		switch desktop {
		case "KDE":
			if kdialog != "" {
				return kdialog, .KDialog, true
			}
			if zenity != "" {
				return zenity, .Zenity, true
			}
		case "GNOME":
			if zenity != "" {
				return zenity, .Zenity, true
			} else if kdialog != "" {
				return kdialog, .KDialog, true
			}
		case "":
			// Probably running in some window manager
			if zenity != "" {
				return zenity, .Zenity, true
			} else if kdialog != "" {
				return kdialog, .KDialog, true
			}
		case:
			unimplemented()
		}
		return
	}

	@(private = "file")
	find_binary_location :: proc(
		name: string,
		allocator := context.temp_allocator,
	) -> (
		path: string,
	) {
		location_buf: [1024]byte
		file := popen(fmt.ctprintf("/usr/bin/env whereis %v", name), "r")
		defer pclose(file)

		fgets(raw_data(location_buf[:]), len(location_buf), file)
		location := string(location_buf[len(fmt.tprintf("%v: ", name)):])
		location, _ = strings.replace_all(location, "\n", "", context.temp_allocator)
		return strings.clone(location)
	}

	@(private = "file")
	execute_binary :: proc(fullpath: string) -> (output: string) {
		location_buf: [1024]byte
		file := popen(cstr(fullpath), "r")
		defer pclose(file)

		fgets(raw_data(location_buf[:]), len(location_buf), file)
		output = string(location_buf[:])
		output, _ = strings.replace_all(output, "\n", "", context.temp_allocator)
		return strings.clone(output)
	}

	open_file_dialog :: proc(filter: ..string, directory: bool = false) -> string {
		switch _, type, _ := find_installed_dialog_binary(); type {
		case .KDialog:
			command: string
			if directory {
				command = fmt.tprintf("kdialog --getexistingdirectory")
			} else {
				if len(filter) == 0 {
					command = fmt.tprintf("kdialog --getopenfilename")
				} else {
					command = fmt.tprintf(
						"kdialog --getopenfilename '%v'",
						strings.join(filter, " "),
					)
				}
			}
			output := execute_binary(command)
			return output
		case .Zenity:
			command: string
			if directory {
				command = fmt.tprintf("zenity --file-selection --directory")
			} else {
				if len(filter) == 0 {
					command = fmt.tprintf("zenity --file-selection")
				} else {
					command = fmt.tprintf(
						"zenity --file-selection --file-filter='%v'",
						strings.join(filter, " "),
					)
				}
			}
			output := execute_binary(command)
			return output
		}
		unimplemented()
	}

	show_popup :: proc(title: string, message: string, type: PopupType) {
		notification_type := type
		switch _, type, _ := find_installed_dialog_binary(); type {
		case .KDialog:
			command: string
			switch notification_type {
			case .Info:
				command = fmt.tprintf("kdialog --title '%v' --msgbox '%v' 5", title, message)
			case .Warning:
				command = fmt.tprintf("kdialog --title '%v' --sorry '%v'", title, message)
			case .Error:
				command = fmt.tprintf("kdialog --title '%v' --error '%v'", title, message)
			}
			execute_binary(command)
		case .Zenity:
			command: string
			switch notification_type {
			case .Info:
				command = fmt.tprintf("zenity --info --title='%v' --text='%v'", title, message)
			case .Warning:
				command = fmt.tprintf("zenity --warning --title='%v' --text='%v'", title, message)
			case .Error:
				command = fmt.tprintf("zenity --error --title='%v' --text='%v'", title, message)
			}
			execute_binary(command)
		}
	}

	cstr :: proc(s: string, allocator := context.temp_allocator) -> cstring {
		return strings.clone_to_cstring(s, allocator)
	}
}
