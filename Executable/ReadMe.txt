TV Show Mover
===========================
DESCRIPTION:
---------------------------------------

TV Show Mover is an application designed to automatically find, sort, and move tv shows to their correct locations after downloading.
Step 1. Update the included tvshowmover.ini file to match your tv shows and locations.
Step 2. Place the exe and ini file in your specified download directory.
Step 3. Configure your downloading tool to run tvshowmover.exe after download.

UPDATES:
---------------------------------------
Version 3.5.0.0 - 11/19/2025
- Added Strict Anchoring: Prevents false positives (e.g. "Riverdale" matching inside other filenames).
- Added Auto-Enrichment: Fetches episode titles for standard "SxxExx" files.
- Added Deep Matching: Handles complex filenames lacking standard S/E numbering.
- Added Dot Separators: Renames files using the "Show.SxxExx.Title.ext" format.
- Added TVMaze lookup function to automatically "normalize" file names, and verify season and episode.

Version 3.0.0.5 - 02/28/2025
- Fixed bug with moving show packs with multiple seasons.
- Added srt files to move function.

Version 3.0.0.4 - 02/28/2025
- Fixed bug with removing leftover folders after file moves.
- Added logging.

Version 3.0.0.2 - 09/27/2024
- Fixed bug with processing folders with illegal characters in the name.

Version 3.0.0.1 - 09/24/2024
- Fixed bug with processing files with illegal characters in the name.

Version 3.0.0.0 - 09/22/2024 
- Reworked code for speed and efficiency.
- Changed Show Format listing in ini file.

Version 2.0.1.0 - 05/17/2024 
- Added ability to create destination folders on the fly based on path in ini file

Version 2.0.0.9 - 02/17/2021 
- Added conversion to replace spaces with periods to simplify auto filing

Version 2.0.0.8 - 10/28/2020 
- Fixed issue with processing tv shows with "S" in the name.

Version 2.0.0.7 - 10/22/2020 
- Fixed issue with deleting and/or moving ini files with tv shows.

Version 2.0.0.6 - 10/14/2020 
- Updated Season and Episode detection to reach to "999" instead of "30".
- Added "clean up" function to delete folder and other files after moving tv show to new location.
- Added function to "clean up" file and folder names, i.e. remove invalid characters from name.

Version 2.0.0.5 - 06/10/2020 
- Further updated and cleaned up logic for tv shows based on ini file paths.

Version 2.0.0.4 - 06/09/2020 
- Fixed issue where shows would not move to the correct folder if folder was empty or missing.

Version 2.0.0.3 - 06/09/2020 
- Removed hard coded paths from executable to allow for running from any directory.
- Added code to determine name, season, and episode of tv show, in order to properly move the file.

Version 2.0.0.0 - 03/20/2019 
- Fixed bug in file moving with certain characters in the name.

Version 1.0.0.0 - 10/12/18 
- Fixed error in tv show sorting.

Version 0.1.0.0 - 05/08/18 
- Initial Creation
