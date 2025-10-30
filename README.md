<div align="center">
  <img src="https://nexosoft-engineering.de/autopyplusplus/git_p.png" alt="Alt-Text" width="250" />
</div>

### Pro Version (Coming soon)

AutoPy++ Pro targets professional users and developers who need hardened builds, reliable workflows, and smooth integration with common IDEs. Building on the open-source core, Pro consolidates and extends functionality while favoring fewer, more stable releases, with clearly defined interfaces between extensions to keep automation predictable. To maintain transparency, essential Python sources remain open, while selected modules are delivered under a PyArmor runtime to enable Pro-only capabilities and performance gains. Pricing is planned at ~€20 per year via a payment platform; the purchase activates a machine-bound license, and all updates released during the active term are included. Overall, Pro emphasizes stability and refinement of what python developer use every day, delivering a clear improvement over the open-source edition. Final commercial and technical details will be confirmed once remaining questions are resolved. 

<div align="center">
  <a href="https://nexosoft-engineering.de/autopyplusplus/mailcheck.html">🐍 Mailcheck 🐍</a>
</div>

### How to get AutoyPy++ Pro?
- Step 1.) Check if your Mail Adress is accepted
- Step 2.) Payment                 (Coming Soon)
- Step 3.) Register                (Coming Soon)
- Step 4.) Donwload & Installation (Coming Soon)
- Step 5.) Activation              (Coming Soon)
- Step 6.a.) Reactivation          (Coming Soon)
- Step 6.b.) Renewal               (Coming Soon)
  
### What to expect
- **Stability over frequency**: fewer, more stable updates
- **Hardening & interfaces**: fully defined extension interfaces and improved robustness
- **Transparent architecture**: core Python files remain open; select components are protected with a **PyArmor runtime** to deliver Pro-only features and performance gains
- **Streamlined UI**: no “About” pop-ups, a cleaner experience
- **Better with IDEs**: enhanced support for build processes across common IDEs

### Licensing & Pricing
- Planned price: **~€20/year**
- Activation via a payment platform; **machine-bound (PC) license**
- Subscription includes **all updates** released during the active term
- Final commercial and technical details will be announced once remaining questions are resolved

### Installation & Activation
AutoPy++ Pro is delivered via a Windows 10/11-32/64-Bit installer. After completing registration and automatic licensing, the software can be used without limitations. Registration requires first name, last name, and an email address. To simplify the process, a built-in Licensing Assistant guides you step by step through registration and activation; once the license is bound to your machine, AutoPy++ Pro starts fully unlocked.

### Minimal system requirements

- **OS:** Windows 10 or Windows 11 (64-bit)
- **CPU:** x86_64, 2+ cores (AVX-capable recommended for best performance)
- **Memory:** 4 GB RAM minimum (8 GB+ recommended)
- **Disk:** ~200 MB for the application (additional space for build artifacts)
- **Network:** Internet connection required for registration, license activation, and updates
- **Permissions:** Local administrator rights for installation; outbound HTTPS access for licensing
- **Display:** 1366×768 minimum (1920×1080 recommended)
- **Dependencies:**
  - Common runtimes (e.g., Microsoft Visual C++ Redistributable) are installed automatically if missing
  - Optional: **Python 3.10–3.13** if you plan to use the CLI/SDK or custom build scripts

### Release focus
This release emphasizes **stability and refinement of existing functionality**, improving reliability and behavior across typical workflows. The Pro edition aims to be a **clear improvement over the open-source version**.

| Component   | Status                        |
|-------------|-------------------------------|
| Virtual Env | works (not fully tested)      |
| Sphinx      | works (not fully tested)      |
| Pytest      | works (not fully tested)      |
| PyInstaller | works well (not fully tested) |
| PyArmor     | works Pro/Basic               |
| Nuitka      | works      (not fully tested) |
| Cython      | works well (not fully tested) |
| MSVC        | works well (not fully tested) |
| Inspector   | works well                    |
| Obfuscator  | experimental                  |
| Secure Compilers | works (not fully tested) |

```
📜 .py
├── 🔨 [PyInstaller] → 💾 .exe (Standalone bundled application)
├── 🔒 [PyArmor] → 🔐 .pyc (Encrypted bytecode, requires PyArmor runtime)
├── ⚙️ [Nuitka]
│   ├── 💾 .exe (Standalone or dependent executable)
│   ├── 🔌 .pyd / .so (Python extension module)
│   └── 🔗 .dll (Rare, Windows DLL)
├── 🛠️ [Cython] → 📄 .c / .cpp → [C/C++ Compiler]
│   ├── 🔌 .pyd (Windows) / .so (Linux/Mac) (Extension module)
│   ├── 💾 .exe (Native executable, rare)
│   ├── 🔗 .dll (Windows DLL, rare)
│   └── 📚 .lib (Static library for C/C++)
└── 📖 [Sphinx] → 🌐 HTML / 📄 PDF / 📚 LaTeX / 📑 man-pages
    ├── ⚡ Uses `conf.py`
    ├── 🔗 Edit your conf.py 
    ├── 📂 Output in `_build/<builder>` (e.g. `_build/html`)
    └── 🎨 Supports pip-installed and custom themes
```

# Known Bugs

**Hard Bugs:**
- Permission denied when compiling spec files:  
  WARNING: Execution of '_append_data_to_exe'  

**Low Bugs:**
- Issues with missing binary libraries (not critical)  
- Nuitka created exe files detected by antivirus (read practice lesson)

---

# Setup & Usage Guide

---
## Important!

**Overwrite `myProject.apyscript` to set the home project for AutoPy++.**


Before you use this software:
> This software is currently under development.  
> **Backup your files before you start compiling!** Errors in the software or incorrect flags could delete your files!  
> It can contain bugs that crash your whole system... use it carefully.  
> Send us error reports with detailed text and screenshots to: info@nexosoft-engineering.de

---

# For MSVC Pipeline Users Only

**Install full development libarys C++** 
- Needet compiler for Windows Applications is MSVC
- https://visualstudio.microsoft.com/de/visual-cpp-build-tools/
  
**How to start MSVC with autoPy++ ?** 
- edit msvc_start.bat with your paths.
- start msvc_start.exe

**Add your MSVC Compiler to Extensions** 
Open under Windows.: x64 Native Tools Command Prompt for VS 2022
```bash
where cl
```


### ONLY FOR MINGW -> MSYS2 commands:
```bash
pacman -Syu
pacman -Su
pacman -S mingw-w64-x86_64-toolchain
pacman -S mingw-w64-x86_64-python
pacman -S python-devel
exit
```

### Check versions:

```bash
gcc --version
g++ --version
python --version
echo $MSYSTEM
```

---

# Hints and Errors

### Software Updates

- Make sure your personal file `extensions_path.ini` is backed up somewhere.
- Ensure new paths for software features are inside your ini file (via Load Config in main GUI).
- Save your custom `.apyscript` file and replace it after updates.
- Every update rollout starts with tests that could fail.
---

# Practice

- For clean usage, **do not change existing names or paths of files** — create new projects instead.
- Press the "Save" button often when making changes in your project settings.

---

# Virtual Environments
```python
- Open File env_setup.ini, here is the basic installation for each virtual environment
  You easly can copy and create a new startup installation setting
- Each virtual environment is a copy of the new system-version.
  If you want to delete a system-version, first delete all linked virtual environments!

```
- Start windows_start.bat
- Wait and press the -V-
- Choose a Python Version for you build
- AutoPy++ installs now reqiuremnts
- Autopy++ starts with python version

---

# Simplex-API Usage

- Set a flag to ON (or any truthy value listed below) to trigger the action.
- The watcher detects a rising edge (OFF -> ON) and runs the action once.
- If AutoReset=true, the watcher will write the flag back to OFF after firing.

- Accepted truthy values: 1, true, on, yes, y, an, ein, aktiv, start
- Accepted falsy values : 0, false, off, no, n, aus, stop
Optional settings:
Mode        : A | B | C       (compile mode to apply before actions)
ThreadCount : integer >=1     (clamped to [1..max threads] in GUI)
AutoReset   : true | false    (true = write flag back to OFF after trigger)

```python
[Simplex Example Configuration]
Compile_all = 1
Inspector = stop
DeleteLogs = true
AutoReset = true
```
---

# Nuitka Usage

To startup nuitka compiled .exe files you need to,
set your compiled .exe file and folder in your Antivirus to secure.
Avira Antivir is usefull here.
Normaly you need a code sign certification, to start
witout changing any properties in your scanner.
```python
set the nutika path like this, direct to primary python installation
nuitka = "C:\Program Files (x86)\Thonny\python.exe"
the system found nuitka in your python version
```
---
# PyArmor Usage

Pyarmor is not for Free, you could only create limited runs in test version
- Go to https://jondy.github.io/paypal/index.html
- Buy Basic or Pro, Wait for Mail (1 hour)
- Download zip file to a created folder like this.: C:\Users\YOURNAME\Documents\PyArmor
```bash
1.) pip install pyarmor
2.) cd C:\Users\YOURNAME\Documents\PyArmor
3.) pyarmor reg -p YOURPRODUCTNAMEHERE pyarmor-regcode-7959.txt  (Creates a Registerfile)
4.) pyarmor reg pyarmor-regfile-7959.zip  (your local licence! dont disclose!)
5.) pyarmor -v (check registration)
6.) For BCC Builds you need the c-compiler clang.exe -> USER/.pyarmor/
7.) Create a Virtual Environment!
First Aid Manuel -> pyarmor.readthedocs.io/en/latest/tutorial/getting-started.html
Clang Compiler   -> pyarmor.dashingsoft.com/downloads/tools/clang-9.0.zip

---
# Sphinx Usage

AutoPy++ builds documentation with [Sphinx](https://www.sphinx-doc.org/).

- **conf.py**  
  Your original Sphinx config. Never modified.

- **conf_autopy.py**  
  Created by AutoPy++ GUI. Loaded *after* `conf.py` and overrides settings.

- **Loading order**  
  1. `conf.py` (base config)  
  2. `conf_autopy.py` (GUI overrides: theme, extensions, options)

- **Themes**  
  - Install via pip (`pip install sphinx_rtd_theme`) → set in GUI.  
  - Custom themes: add path in `conf.py` → can still override in GUI.  

- **Result**  
  Base config stays intact. GUI changes are applied via `conf_autopy.py`.  
  Delete `conf_autopy.py` to revert to pure `conf.py`.


---
# MSVC Python Extension Usage
- Start msvc_start.bat
- Activate cython in script
- Target Type: Python Extension
- Activate cython C++ Pipepline
- Open C++ Pipline
- Target Type: Python Extension
- Insert python3XX.dll
- add include & libary dirs from python
- add Libaries: python3XX

If you have problems with missing python extensions, load yourextension.pyd
in with this nice tool.:
```link
https://github.com/lucasg/Dependencies
```
That will show you missing files and more.

---
# GCC/G++ Notes

If you have problems with missing `.dll` files, set the compiler path to the global system path under Windows 10/11.

Example PowerShell commands (run as admin):

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\msys64\mingw64\bin", [EnvironmentVariableTarget]::Machine)
echo $env:Path
g++ --version
gcc --version
```

---



