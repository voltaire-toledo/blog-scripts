# Seal-Image.ps1

> "Because every Windows image deserves a spa day before it becomes a template."

## 🦭 What is Seal-Image.ps1?

Seal-Image.ps1 is your one-stop, all-in-one, do-it-all PowerShell script for prepping (a.k.a. "sealing") a Windows VM before you run Sysprep and immortalize it as a golden template. Think of it as a digital janitor, therapist, and bouncer for your OS—cleaning up, calming down, and kicking out the riff-raff before the big snapshot.

## 🚀 Features & Actions (a.k.a. "What does this thing actually do?")

Here’s the full spa treatment your VM gets:

- **Manifest Collection:** Prompt the admin for a list of changes (or skip if you’re feeling mysterious).
- **Transcript Logging:** Everything is logged, so you can blame the script later.
- **Display Installed Hotfixes:** Because you should know what’s been patched before you clone.
- **Update PowerShell Help:** Even your help files get a glow-up.
- **Clear All Event Logs:** Classic and modern logs—gone! (Like your memory after a long weekend.)
- **Clear IE Cookies, History, etc.:** For that fresh browser smell.
- **Empty Downloaded MS Updates Folder:** Out with the old, in with the new.
- **Remove Phantom Drive Mappings:** Ghostbusters, but for network drives.
- **Clear Temp Folders:** Because nobody likes digital clutter.
- **Delete Unnecessary User Profiles:** DELPROF2 does the dirty work.
- **Apply Group Policy:** gpupdate.exe /force, because rules are rules.
- **Uninstall GFI Agent:** Bye, Felicia.
- **Disable Hibernate:** No more naps for you, Windows.
- **Disable Windows Update Service:** Because surprises are for birthdays, not templates.
- **Disable Google Update Services:** Chrome, you’re not the boss of me.
- **Disable Adobe Acrobat Update Service:** No more unsolicited updates.
- **Clear Citrix UPM Logs:** Out with the old profiles.
- **Flush DNS Cache:** Because stale DNS is so last season.
- **Release IP Lease:** Let someone else have a turn.
- **Windows Defender Cleanup:** Remove logs and quarantine—Defender’s memory wiped.
- **Remove Ghost Devices:** (Manual/devcon) – Boo!
- **Clear Print Spooler:** No more ghost print jobs.
- **Component Store Cleanup (DISM):** The nuclear option for WinSxS bloat.
- **Remove Custom Scheduled Tasks:** Because you don’t need that 3am “remind me to stretch” task.
- **Remove Old Network Profiles:** Out with the old Wi-Fi, in with the new.
- **Remove Unwanted Appx Packages:** Bye, Candy Crush.
- **Wipe Free Space:** (Manual/SDelete) – For that zeroed-out feeling.
- **Remove Custom Branding:** No more corporate tattoos.
- **Sysprep Integration:** (Optional) – The final curtain call.
- **Reset TS Grace Period:** For Server OS only. Because even servers need a second chance.

## 🛠️ Requirements

- **Run as Administrator** (seriously, don’t make me nag)
- PowerShell 5.1+
- [DELPROF2.EXE](https://helgeklein.com/download/) ([info](https://helgeklein.com/free-tools/delprof2-user-profile-deletion-tool/)) – for user profile cleanup
- [Reset-TSGracePeriod.ps1](https://github.com/adamgell/Scripts/blob/master/Reset-TSGracePeriod.ps1) – for server grace period reset *(link may require manual download from GitHub)*
- [SDelete](https://download.sysinternals.com/files/SDelete.zip) ([info](https://docs.microsoft.com/en-us/sysinternals/downloads/sdelete)) – optional, for free space wipe
- [devcon.exe](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon) – optional, for ghost device removal *(included in Windows Driver Kit, see link for details)*

## 🧑‍💻 Usage

```powershell
# Open an admin PowerShell window
PS> .\Seal-Image.ps1 [-SkipManifest] [-PromptAll]
```

- `-SkipManifest`: Don’t prompt for admin change log.
- `-PromptAll`: Prompt for every action (for the control freak in all of us).

## 📦 Output

- `Seal-Image-Transcript_<date_time>.log` – The play-by-play.
- `Seal-Image-Manifest.log` – The admin’s confessions.

## 📝 Next Up (a.k.a. "Coming Soon to a Script Near You")

- **Automatic detection and download of required tools (DELPROF2, devcon, SDelete, etc.)**
- **GUI front-end (because buttons are fun)**
- **More granular logging (with emojis?)**
- **Cloud upload of logs (for the truly paranoid)**
- **Support for Windows 12 (if/when it exists)**
- **AI-powered snarky comments for every action**
- **Make the script self-aware (just kidding… or am I?)**

## 🤔 FAQ

**Q: Is this script safe?**  
A: As safe as a script that deletes logs, profiles, and disables services can be. Read the code, run in a test VM, and don’t blame me if you nuke your prod image.

**Q: Why so many jokes?**  
A: Because IT is hard enough. Laughter is the best (error) handler.

**Q: Can I contribute?**  
A: PRs welcome! Just don’t break the mood.

---

> “Seal-Image.ps1: Because every VM deserves to look its best before being cloned for eternity.”
