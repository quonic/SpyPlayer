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

spectrum_texture: raylib.Texture2D

GenerateSpectrum :: proc() {
	// Generate spectrum

	// Get the temp file path
	temp_path := newTempFile("png")

	// Remove the temp file if it exists
	if os.exists(temp_path) {
		errremove := os.remove(temp_path)
		if errremove != nil {
			fmt.eprintf("Error removing temp file: %v", errremove)
		}
	}

	fmt.printfln("Loading spectrum for %s", playList[currentSongIndex].path)

	// Generate the spectrum using ffmpeg
	ffmpeg_spectrum_path := fmt.aprintf(
		"ffmpeg -i %s -lavfi showspectrumpic=legend=0:s=%dx%d:opacity=0 %s -y",
		playList[currentSongIndex].path,
		i32(meter_bar.positionRec.width * 10),
		i32(meter_bar.positionRec.height * 10),
		temp_path,
	)

	fmt.printfln("Executing: %s", ffmpeg_spectrum_path)

	// Split the command into an array
	cmd := strings.split(ffmpeg_spectrum_path, " ")

	// Execute the command
	state, stdout, stderr, proc_err := os2.process_exec(
		os2.Process_Desc{command = cmd},
		context.allocator,
	)

	if state.exit_code != 0 || proc_err != nil {
		fmt.printfln("Error: Process Error: %v", proc_err)
		fmt.printfln("----------------- STDOUT --------------------")
		fmt.printfln("%s", transmute(string)stdout)
		fmt.printfln("----------------- STDERR --------------------")
		fmt.printfln("%s", transmute(string)stderr)
		fmt.printfln("----------------- STATUS --------------------")
		fmt.printfln("%v", state)
	}

	if os.exists(temp_path) {
		fmt.printfln("Loading spectrum texture")
		// Load the spectrum texture
		spectrum_texture = raylib.LoadTexture(strings.clone_to_cstring(temp_path))
		// Remove the temp file
		errremove := os.remove(temp_path)
		if errremove != nil {
			fmt.eprintf("Error removing temp file: %v", errremove)
		}
	}
}
