package main

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:path/filepath"
import "core:strings"
import "vendor:raylib"

GetXdgConfigHome :: proc() -> (string, os.Error) {
	XDG_CONFIG_HOME := os.get_env("XDG_CONFIG_HOME")
	if XDG_CONFIG_HOME != "" {
		return XDG_CONFIG_HOME, nil
	} else {
		return filepath.join({os.get_env("HOME"), ".config"})
	}
}

GetConfigFilePath :: proc() -> (string, os.Error) {
	XDG_CONFIG_HOME, err := GetXdgConfigHome()
	if err != nil {
		return "", err
	}
	return filepath.join({XDG_CONFIG_HOME, "SpyPlayer", "config.json"}), nil
}

newTempFile :: proc(extension: string) -> string {
	when ODIN_OS == .Windows {
		return filepath.join({os.get_env("TEMP"), fmt.aprintf("temp_spyplayer.%s", extension)})
	} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		return filepath.join({"/tmp", fmt.aprintf("temp_spyplayer.%s", extension)})
	}
}

AudioProcessFFT :: proc "c" (bufferData: rawptr, frames: u32) {

}
