# TV Show Mover

**TV Show Mover** is a robust, automated media organization tool designed to scan download directories, identify TV show files, fetch metadata, and move them to their permanent library locations.

Unlike standard renamers, this tool uses a **"Strict Anchored Match"** system against a user-defined configuration to prevent false positives, combined with **Deep API Matching** to handle complex, messy, or multi-episode filenames.

---

## 🚀 Key Features

* **Strict Anchoring:** Prevents mismatching. Matches only occur if the filename *starts* with a Show Name defined in your configuration (e.g., "Riverdale" will not match "The Prince of Riverdale").
* **Auto-Enrichment:** Automatically queries the **TVMaze API** to fetch official Episode Titles for files that only contain `SxxExx` numbering.
* **Deep Matching:** Handles non-standard naming conventions (e.g., files with missing Season numbers or complex separators like `.-.`).
* **Multi-Episode Support:** Detects and formats double episodes (e.g., `S01E01-E02`).
* **Fuzzy Logic:** Intelligently handles punctuation differences (e.g., matching "Surf-Bored" to "Surf Bored").
* **Sanitization:** Automatically strips Windows-illegal characters from filenames.
* **Smart Cleanup:** Deletes source folders automatically after all files within them have been successfully moved.

---

## ⚙️ Configuration

The application relies on a configuration file named `TVShowMover.ini` located in the same directory as the executable (or the target download directory).

### 🛠️ INI File Structure

The INI file acts as an **Allowlist**. If a show is not in this file, the tool will ignore it.

**Format:** `Name of Show = Path to Destination Folder`

> **Important:** The "Name of Show" (Key) must match the **start** of your filenames exactly (case-insensitive).

    [Shows]
    # Standard Mapping
    The Office = D:\Media\TV Shows\The Office (2005)

    # Handle Apostrophes explicitly if filenames contain them
    The New Archie's = T:\KidsTV\The New Archies

    # Files starting with "Sabrina" go here
    Sabrina = T:\KidsTV\Sabrina The Teenage Witch (1971)

    # Files starting with the full title ALSO go here (Multiple keys, same path)
    Sabrina The Teenage Witch = T:\KidsTV\Sabrina The Teenage Witch (1971)

---

## 🛠️ How It Works

1.  **Scan:** The tool scans the target directory for video files (`.mp4`, `.mkv`, `.avi`).
2.  **Anchor Match:** It checks if the filename starts with any known Show Name found in your settings.
3.  **Parse & Lookup:**
    * **Standard Match:** If it finds `SxxExx`, it queries the internet for the episode title.
    * **Deep Match:** If standard numbering is missing, it analyzes the text in the filename and performs a fuzzy search against the show's episode list.
4.  **Rename:** Files are renamed using the Dot convention: `Show.SxxExx.Title.ext`.
5.  **Move:** The file is moved to `Destination Path\Season XX\`.
6.  **Log:** Every action (success, skip, or error) is recorded in a local `.log` file.

---

## ⚡ Usage

1️⃣ Default Scan using current folder and default ini file (TVShowMover.ini):
```command
TVShowMover.exe
```

1️⃣ Scan a specific downloads folder:
```command
TVShowMover.exe -DownloadDirectory "D:\Downloads\Incoming"
```

Use a specific config file:
```command
TVShowMover.exe -IniFileName "MyConfig.ini"
```

Combine arguments:
```command
TVShowMover.exe -DownloadDirectory "E:\Torrents" -IniFileName "KidsTV.ini"
```

---

## 📜 Version History

### Version 3.5.0.3 - 11/20/2025
* Fixed crash when destination filenames contain special characters (brackets `[]` or parentheses `()`) by using `-LiteralPath` for all file existence checks.

### Version 3.5.0.2 - 11/20/2025
* Fixed critical bug with square brackets `[]` in source filenames preventing moves.
* Added Smart Season detection: Defaults to existing "Season 1" folders to prevent creating "Season 01" duplicates.

### Version 3.5.0.0 - 11/19/2025
* Added Strict Anchoring: Prevents false positives (e.g. "Riverdale" matching inside other filenames).
* Added Auto-Enrichment: Fetches episode titles for standard "SxxExx" files.
* Added Deep Matching: Handles complex filenames lacking standard S/E numbering.
* Added Dot Separators: Renames files using the "Show.SxxExx.Title.ext" format.
* Added TVMaze lookup function to automatically "normalize" file names, and verify season and episode.

### Version 3.0.0.6 - 03/02/2025
* Added scan for files with underscores in the name.

### Version 3.0.0.5 - 02/28/2025
* Fixed bug with moving show packs with multiple seasons.
* Added srt files to move function.

### Version 3.0.0.4 - 02/28/2025
* Fixed bug with removing leftover folders after file moves.
* Added logging.

### Version 3.0.0.2 - 09/27/2024
* Fixed bug with processing folders with illegal characters in the name.

### Version 3.0.0.1 - 09/24/2024
* Fixed bug with processing files with illegal characters in the name.

### Version 3.0.0.0 - 09/22/2024
* Reworked code for speed and efficiency.
* Changed Show Format listing in ini file.

### Version 2.0.1.0 - 05/17/2024
* Added ability to create destination folders on the fly based on path in ini file

### Version 2.0.0.9 - 02/17/2021
* Added conversion to replace spaces with periods to simplify auto filing

### Version 2.0.0.8 - 10/28/2020
* Fixed issue with processing tv shows with "S" in the name.

### Version 2.0.0.7 - 10/22/2020
* Fixed issue with deleting and/or moving ini files with tv shows.

### Version 2.0.0.6 - 10/14/2020
* Updated Season and Episode detection to reach to "999" instead of "30".
* Added "clean up" function to delete folder and other files after moving tv show to new location.
* Added function to "clean up" file and folder names, i.e. remove invalid characters from name.

### Version 2.0.0.5 - 06/10/2020
* Further updated and cleaned up logic for tv shows based on ini file paths.

### Version 2.0.0.4 - 06/09/2020
* Fixed issue where shows would not move to the correct folder if folder was empty or missing.

### Version 2.0.0.3 - 06/09/2020
* Removed hard coded paths from executable to allow for running from any directory.
* Added code to determine name, season, and episode of tv show, in order to properly move the file.

### Version 2.0.0.0 - 03/20/2019
* Fixed bug in file moving with certain characters in the name.

### Version 1.0.0.0 - 10/12/18
* Fixed error in tv show sorting.

### Version 0.1.0.0 - 05/08/18
* Initial Creation

---

## 📝 Credits

* **Author:** Carl Roach
* **Copyright:** 2025


```
