<# 
    AutoPy++ System Requirements Checker (Windows 10/11)
    Tailored for https://github.com/melatroid/autoPyPlusPlus
    - Checks: OS build, RAM, Free disk
              Python (>=3.10) & pip
              Git
    - WPF GUI + English report export
#>

# --------------------------
# 0) Configurable thresholds
# --------------------------
$Req = [ordered]@{
  "OS Build (>=)"            = 19041
  "RAM (GB >=)"              = 4
  "CPU Cores (>=)"           = 2
  "Free System Disk (GB >=)" = 1
  "Python Min Version"       = "3.10.0"
  "Git Required"             = $true
  "Require Tools"            = @()
  "Require MSVC (cl.exe)"    = $true
  "MSVC Path Override"       = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe"
}

# --------------------------
# 1) Helpers
# --------------------------
function Convert-BytesToGB([long]$bytes) {
  if ($bytes -le 0) { return 0 }
  [Math]::Round($bytes / 1GB, 2)
}

function Get-OSBuild {
  try { [int](Get-CimInstance Win32_OperatingSystem).BuildNumber } catch { $null }
}

function Get-OSCaption {
  try { (Get-CimInstance Win32_OperatingSystem).Caption } catch { $null }
}

function Get-OSIsSupported {
  try {
    $cap = Get-OSCaption
    if (-not $cap) { return $false }
    return ($cap -match 'Windows 10' -or $cap -match 'Windows 11')
  } catch { $false }
}

function Get-RAMGB {
  try { [int][math]::Floor((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB) } catch { $null }
}

function Get-CPUCoreCount {
  try {
    $sum = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
    if (-not $sum) { $null } else { [int]$sum }
  } catch { $null }
}

function Get-FreeSystemDiskGB {
  try {
    $sys = $env:SystemDrive; if ([string]::IsNullOrWhiteSpace($sys)) { $sys = "C:" }
    $d = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$sys'"
    Convert-BytesToGB([int64]$d.FreeSpace)
  } catch { $null }
}

function Compare-Version($a,$b) {
  try { [Version]$a -ge [Version]$b } catch { $false }
}

# --- System summary helper ---
function Get-SystemSummary {
  try {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
  } catch { $os = $null; $cs = $null }

  $sysDrive = if ([string]::IsNullOrWhiteSpace($env:SystemDrive)) { "C:" } else { $env:SystemDrive }
  [pscustomobject]@{
    MachineName   = $env:COMPUTERNAME
    UserName      = $env:USERNAME
    OSCaption     = $os.Caption
    OSVersion     = $os.Version
    OSBuild       = $os.BuildNumber
    OSArch        = $os.OSArchitecture
    RAM_GB        = if ($cs) { [int][math]::Floor($cs.TotalPhysicalMemory / 1GB) } else { $null }
    SystemDrive   = $sysDrive
    FreeSysDiskGB = Get-FreeSystemDiskGB
    TimeZone      = (Get-TimeZone).Id
  }
}

# --- Hardware/CPU/GPU/Board/RAM zusammenfassen ---
function Get-HardwareSummary {
  try {
    $cs   = Get-CimInstance Win32_ComputerSystem
    $cpu  = Get-CimInstance Win32_Processor
    $bb   = Get-CimInstance Win32_BaseBoard
    $bios = Get-CimInstance Win32_BIOS
    $gpu  = Get-CimInstance Win32_VideoController | Sort-Object CurrentVerticalResolution -Descending | Select-Object -First 1
    $mem  = Get-CimInstance Win32_PhysicalMemory
  } catch {}

  # CPU-Aggregation (falls mehrere Sockets)
  $totalCores = ($cpu  | Measure-Object -Property NumberOfCores -Sum).Sum
  $totalLog   = ($cpu  | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
  $baseClock  = ($cpu  | Measure-Object -Property MaxClockSpeed -Maximum).Maximum
  $curClock   = ($cpu  | Measure-Object -Property CurrentClockSpeed -Maximum).Maximum
  $smtEnabled = $totalLog -gt $totalCores

  # RAM-Module
  $memModules = @()
  if ($mem) {
    $memModules = $mem | ForEach-Object {
      [pscustomobject]@{
        BankLabel    = $_.BankLabel
        CapacityGB   = [math]::Round($_.Capacity/1GB, 0)
        SpeedMHz     = $_.Speed
        Manufacturer = $_.Manufacturer
        PartNumber   = $_.PartNumber
        SerialNumber = $_.SerialNumber
      }
    }
  }

  # Alle lokalen Laufwerke (DriveType=3)
  $drives = @()
  try {
    $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
      [pscustomobject]@{
        Drive  = $_.DeviceID
        Label  = $_.VolumeName
        FS     = $_.FileSystem
        FreeGB = [math]::Round(($_.FreeSpace  / 1GB), 2)
        SizeGB = [math]::Round(($_.Size       / 1GB), 2)
      }
    }
  } catch {}

  [pscustomobject]@{
    CPU = [pscustomobject]@{
      Name     = ($cpu | Select-Object -ExpandProperty Name -First 1)
      Sockets  = ($cpu | Measure-Object).Count
      Cores    = $totalCores
      Logical  = $totalLog
      SMT      = if ($smtEnabled) { "Enabled" } else { "Disabled/NA" }
      BaseMHz  = $baseClock
      CurrMHz  = $curClock
      L3KB     = ($cpu | Measure-Object -Property L3CacheSize -Maximum).Maximum
      VT_x     = ($cpu | Select-Object -ExpandProperty VirtualizationFirmwareEnabled -First 1)
      SLAT     = ($cpu | Select-Object -ExpandProperty SecondLevelAddressTranslationExtensions -First 1)
      AddrW    = ($cpu | Select-Object -ExpandProperty AddressWidth -First 1)
      DataW    = ($cpu | Select-Object -ExpandProperty DataWidth -First 1)
    }
    Board = [pscustomobject]@{
      Manufacturer = $bb.Manufacturer
      Product      = $bb.Product
    }
    BIOS = [pscustomobject]@{
      Vendor   = $bios.Manufacturer
      Version  = $bios.SMBIOSBIOSVersion
      Release  = ($bios.ReleaseDate | Get-Date -ErrorAction SilentlyContinue)
    }
    GPU = [pscustomobject]@{
      Name     = $gpu.Name
      DriverV  = $gpu.DriverVersion
      VRAMGB   = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM/1GB, 2) } else { $null }
      Res      = if ($gpu.CurrentHorizontalResolution) { "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)" } else { $null }
    }
    Memory = [pscustomobject]@{
      Modules = $memModules
      TotalGB = if ($cs) { [int][math]::Floor($cs.TotalPhysicalMemory / 1GB) } else { $null }
    }
    Drives = $drives
  }
}

# -- Python detection (prefer py.exe, fallback to python.exe)
function Get-PythonInfo {
  $info = [pscustomobject]@{ Found=$false; Path=$null; Version=$null; Pip=$null }
  $candidates = @(
    @{cmd="py";      args="-3 --version"},
    @{cmd="py";      args="--version"},
    @{cmd="python";  args="--version"},
    @{cmd="python3"; args="--version"}
  )
  foreach ($c in $candidates) {
    try {
      $p = (Get-Command $c.cmd -ErrorAction Stop).Source
      $verOut = & $c.cmd $c.args 2>&1
      if ($LASTEXITCODE -eq 0 -or $verOut) {
        if ($verOut -match "([0-9]+\.[0-9]+(\.[0-9]+)?)") {
          $info.Found   = $true
          $info.Path    = $p
          $info.Version = $Matches[1]
          break
        }
      }
    } catch {}
  }
  if ($info.Found) {
    try {
      $pip = (Get-Command pip -ErrorAction Stop).Source
      $info.Pip = $pip
    } catch {
      $info.Pip = "python -m pip"
    }
  }
  $info
}

function Test-CliPresent($name, $args="--version") {
  try {
    $cmd = Get-Command $name -ErrorAction Stop
    $ver = (& $name $args) 2>&1 | Select-Object -First 1
    return [pscustomobject]@{ Present=$true; Path=$cmd.Source; VersionLine=$ver }
  } catch { 
    return [pscustomobject]@{ Present=$false; Path=$null; VersionLine=$null }
  }
}

function Get-ToolVersion($tool) {
  switch ($tool) {
    "pyinstaller" { (Test-CliPresent "pyinstaller" "--version") }
    "nuitka"      { (Test-CliPresent "nuitka" "--version") }
    "cython"      { (Test-CliPresent "cython" "--version") }
    "pyarmor"     { (Test-CliPresent "pyarmor" "--version") }
    "pytest"      { (Test-CliPresent "pytest" "--version") }
    "sphinx-build"{ (Test-CliPresent "sphinx-build" "--version") }
    default       { (Test-CliPresent $tool "--version") }
  }
}

function Test-MSVC {
  param([string]$OverridePath)

  # 0) Fester Override-Pfad vom User
  if ($OverridePath -and (Test-Path $OverridePath)) {
    return [pscustomobject]@{ Present = $true; Path = (Resolve-Path $OverridePath).Path }
  }

  # 1) Im PATH?
  $cl = Get-Command cl.exe -ErrorAction SilentlyContinue
  if ($cl) { return [pscustomobject]@{ Present = $true; Path = $cl.Source } }

  # 2) vswhere (Visual Studio / Build Tools)
  $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vswhere) {
    try {
      $installPath = & $vswhere -latest `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath 2>$null
      if ($installPath) {
        $vcToolsRoot = Join-Path $installPath "VC\Tools\MSVC"
        if (Test-Path $vcToolsRoot) {
          $verDir = Get-ChildItem -Directory $vcToolsRoot | Sort-Object Name -Descending | Select-Object -First 1
          if ($verDir) {
            foreach ($rel in @("bin\Hostx64\x64\cl.exe","bin\Hostx64\x86\cl.exe","bin\Hostx86\x86\cl.exe")) {
              $c = Join-Path $verDir.FullName $rel
              if (Test-Path $c) { return [pscustomobject]@{ Present = $true; Path = $c } }
            }
          }
        }
      }
    } catch {}
  }

  # 3) Umgebungsvariable aus Dev Prompt
  if ($env:VCToolsInstallDir) {
    foreach ($rel in @("bin\Hostx64\x64\cl.exe","bin\Hostx64\x86\cl.exe","bin\Hostx86\x86\cl.exe")) {
      $c = Join-Path $env:VCToolsInstallDir $rel
      if (Test-Path $c) { return [pscustomobject]@{ Present = $true; Path = $c } }
    }
  }

  # 4) Übliche Fallback-Pfade (inkl. (x86))
  $roots = @(
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC"
  )
  foreach ($root in $roots) {
    if (Test-Path $root) {
      $verDir = Get-ChildItem -Directory $root | Sort-Object Name -Descending | Select-Object -First 1
      if ($verDir) {
        foreach ($rel in @("bin\Hostx64\x64\cl.exe","bin\Hostx64\x86\cl.exe","bin\Hostx86\x86\cl.exe")) {
          $c = Join-Path $verDir.FullName $rel
          if (Test-Path $c) { return [pscustomobject]@{ Present = $true; Path = $c } }
        }
      }
    }
  }

  # Nicht gefunden
  [pscustomobject]@{ Present = $false; Path = $null }
}

# --------------------------
# 2) Run all checks
# --------------------------
function Invoke-Checks {
  $rows = New-Object System.Collections.ArrayList

  # OS Supported (neu/explicit)
  $osCaption  = Get-OSCaption
  $osSupported= Get-OSIsSupported
  [void]$rows.Add([pscustomobject]@{
    Item     = "OS Supported"
    Required = "Windows 10 or 11"
    Actual   = $osCaption
    Passed   = $osSupported
  })

  # OS Build
  $osBuild = Get-OSBuild
  $passOS  = ($osBuild -ge [int]$Req["OS Build (>=)"])
  [void]$rows.Add([pscustomobject]@{ Item="OS Build"; Required=">= $($Req["OS Build (>=)"])"; Actual=$osBuild; Passed=$passOS })

  # RAM
  $ram = Get-RAMGB
  [void]$rows.Add([pscustomobject]@{ Item="Installed RAM (GB)"; Required=">= $($Req["RAM (GB >=)"])"; Actual=$ram; Passed=($ram -ge $Req["RAM (GB >=)"]) })

  # CPU Cores
  $coresReq = [int]$Req["CPU Cores (>=)"]
  $cores    = Get-CPUCoreCount
  [void]$rows.Add([pscustomobject]@{
    Item     = "CPU Cores"
    Required = ">= $coresReq"
    Actual   = $cores
    Passed   = ($cores -ge $coresReq)
  })

  # Disk
  $free = Get-FreeSystemDiskGB
  [void]$rows.Add([pscustomobject]@{ Item="Free System Disk (GB)"; Required=">= $($Req["Free System Disk (GB >=)"])"; Actual=$free; Passed=($free -ge $Req["Free System Disk (GB >=)"]) })

  # Python
  $py = Get-PythonInfo
  $pyPass = $false
  if ($py.Found -and $py.Version) { $pyPass = Compare-Version $py.Version $Req["Python Min Version"] }
  [void]$rows.Add([pscustomobject]@{ Item="Python"; Required=">= $($Req["Python Min Version"])"; Actual= if($py.Found){"$($py.Version) ($($py.Path))"}else{"Not found"}; Passed=$pyPass })

  # pip
  [void]$rows.Add([pscustomobject]@{ Item="pip"; Required="Present"; Actual= if($py.Pip){$py.Pip}else{"Not found"}; Passed=[bool]$py.Pip })

  # Git
  $gitReq = [bool]$Req["Git Required"]
  $git    = Test-CliPresent "git" "--version"
  [void]$rows.Add([pscustomobject]@{ Item="Git"; Required= if($gitReq){"Present"}else{"Optional"}; Actual= if($git.Present){$git.VersionLine}else{"Not found"}; Passed= if($gitReq){$git.Present}else{$true} })

  # Tools (optional list)
  $tools = @($Req["Require Tools"]) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  foreach ($t in $tools) {
    $tinfo = Get-ToolVersion $t
    [void]$rows.Add([pscustomobject]@{
      Item     = "Tool: $t"
      Required = "Present"
      Actual   = if ($tinfo.Present) { $tinfo.VersionLine } else { "Not found" }
      Passed   = [bool]$tinfo.Present
    })
  }

  # MSVC
  $msvcReq = [bool]$Req["Require MSVC (cl.exe)"]
  $msvc    = Test-MSVC -OverridePath $Req["MSVC Path Override"]
  [void]$rows.Add([pscustomobject]@{
    Item     = "MSVC (cl.exe)"
    Required = if ($msvcReq) { "Present" } else { "Optional" }
    Actual   = if ($msvc.Present) { $msvc.Path } else { "Not found" }
    Passed   = if ($msvcReq) { $msvc.Present } else { $true }
  })

  [pscustomobject]@{
    Rows    = $rows
    Details = [pscustomobject]@{
      Python = $py
      Git    = $git
      MSVC   = $msvc
    }
  }
}

# --------------------------
# 3) Report
# --------------------------
function New-ReportText($checkResult) {
  $rows = $checkResult.Rows
  $ts   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $passCount = ($rows | Where-Object Passed).Count
  $total     = $rows.Count
  $overall   = if ($passCount -eq $total) { "PASS" } else { "FAIL" }

  $sys = Get-SystemSummary
  $hw  = Get-HardwareSummary

  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("=== AutoPy++ System Validation Report ===")
  [void]$sb.AppendLine("Timestamp: $ts")
  [void]$sb.AppendLine("Overall Result: $overall ($passCount of $total checks passed)")
  [void]$sb.AppendLine("")

  # --- CPU (Kurzinfo im Kopf) ---
  if ($hw -and $hw.CPU) {
    [void]$sb.AppendLine("CPU:")
    [void]$sb.AppendLine(("  Name          : {0}" -f $hw.CPU.Name))
    [void]$sb.AppendLine(("  Sockets       : {0}" -f $hw.CPU.Sockets))
    [void]$sb.AppendLine(("  Cores         : {0}" -f $hw.CPU.Cores))
    [void]$sb.AppendLine(("  Logical (SMT) : {0} ({1})" -f $hw.CPU.Logical, $hw.CPU.SMT))
    if ($hw.CPU.BaseMHz) { [void]$sb.AppendLine(("  Base Clock    : {0} MHz" -f $hw.CPU.BaseMHz)) }
    if ($hw.CPU.CurrMHz) { [void]$sb.AppendLine(("  Curr Clock    : {0} MHz" -f $hw.CPU.CurrMHz)) }
    [void]$sb.AppendLine("")
  }

  # --- System summary ---
  [void]$sb.AppendLine("System:")
  [void]$sb.AppendLine(("  Machine       : {0}" -f $sys.MachineName))
  [void]$sb.AppendLine(("  User          : {0}" -f $sys.UserName))
  [void]$sb.AppendLine(("  Windows       : {0}" -f $sys.OSCaption))
  [void]$sb.AppendLine(("  Version/Build : {0} (Build {1})" -f $sys.OSVersion, $sys.OSBuild))
  [void]$sb.AppendLine(("  Architecture  : {0}" -f $sys.OSArch))
  [void]$sb.AppendLine(("  Installed RAM : {0} GB" -f $sys.RAM_GB))
  [void]$sb.AppendLine(("  System Drive  : {0}" -f $sys.SystemDrive))
  [void]$sb.AppendLine(("  Free on System: {0} GB" -f $sys.FreeSysDiskGB))
  [void]$sb.AppendLine(("  Time Zone     : {0}" -f $sys.TimeZone))
  if ($Req["MSVC Path Override"]) {
    [void]$sb.AppendLine(("  MSVC Override : {0}" -f $Req["MSVC Path Override"]))
  }
  [void]$sb.AppendLine("")

  # --- Check details ---
  [void]$sb.AppendLine("Details:")
  foreach ($r in $rows) {
    $status = if ($r.Passed) { "PASS" } else { "FAIL" }
    [void]$sb.AppendLine(("{0,-26} Required: {1,-14} | Actual: {2,-60} | {3}" -f $r.Item, $r.Required, ($r.Actual -as [string]), $status))
  }

  $sb.ToString()
}

# --------------------------
# 4) WPF UI
# --------------------------
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AutoPy++ System Checker" Height="650" Width="980"
        WindowStartupLocation="CenterScreen" Background="#0F172A" Foreground="#E5E7EB"
        FontFamily="Segoe UI" FontSize="13">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Margin" Value="6"/>
      <Setter Property="Padding" Value="10,6"/>
      <Setter Property="Background" Value="#1F2937"/>
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Setter Property="BorderBrush" Value="#374151"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
  </Window.Resources>

  <Grid Margin="16">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="2*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Grid.Row="0" VerticalAlignment="Center">
      <TextBlock Text="AutoPy++ System Checker" FontSize="20" FontWeight="Bold" />
    </StackPanel>

    <!-- Configured Requirements (BLACK TEXT) -->
    <GroupBox Grid.Row="1" Header="Configured Requirements" Foreground="#E5E7EB" Background="#111827">
      <DataGrid Name="ReqGrid"
                AutoGenerateColumns="False"
                CanUserAddRows="False"
                IsReadOnly="True"
                Background="White"
                Foreground="Black"
                BorderBrush="#374151">
        <DataGrid.Resources>
          <Style TargetType="DataGridColumnHeader">
            <Setter Property="Foreground" Value="Black"/>
            <Setter Property="Background" Value="#F3F4F6"/>
          </Style>
          <Style TargetType="DataGridCell">
            <Setter Property="Foreground" Value="Black"/>
            <Style.Triggers>
              <Trigger Property="IsSelected" Value="True">
                <Setter Property="Foreground" Value="Black"/>
                <Setter Property="Background" Value="#DDEAFE"/>
              </Trigger>
            </Style.Triggers>
          </Style>
          <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="Black"/>
          </Style>
          <Style TargetType="TextBox">
            <Setter Property="Foreground" Value="Black"/>
          </Style>
        </DataGrid.Resources>
        <DataGrid.Columns>
          <DataGridTextColumn Header="Item" Binding="{Binding Key}" Width="2*">
            <DataGridTextColumn.ElementStyle>
              <Style TargetType="TextBlock">
                <Setter Property="Foreground" Value="Black"/>
              </Style>
            </DataGridTextColumn.ElementStyle>
            <DataGridTextColumn.EditingElementStyle>
              <Style TargetType="TextBox">
                <Setter Property="Foreground" Value="Black"/>
              </Style>
            </DataGridTextColumn.EditingElementStyle>
          </DataGridTextColumn>
          <DataGridTextColumn Header="Required" Binding="{Binding Value}" Width="*">
            <DataGridTextColumn.ElementStyle>
              <Style TargetType="TextBlock">
                <Setter Property="Foreground" Value="Black"/>
              </Style>
            </DataGridTextColumn.ElementStyle>
            <DataGridTextColumn.EditingElementStyle>
              <Style TargetType="TextBox">
                <Setter Property="Foreground" Value="Black"/>
              </Style>
            </DataGridTextColumn.EditingElementStyle>
          </DataGridTextColumn>
        </DataGrid.Columns>
      </DataGrid>
    </GroupBox>

    <GroupBox Grid.Row="2" Header="Check Results" Foreground="#E5E7EB" Background="#111827" Margin="0,10,0,10">
      <DataGrid Name="ResultGrid"
                AutoGenerateColumns="False"
                CanUserAddRows="False"
                IsReadOnly="True"
                Background="White"
                Foreground="Black"
                BorderBrush="#374151">
        <DataGrid.Resources>
          <Style TargetType="DataGridColumnHeader">
            <Setter Property="Foreground" Value="Black"/>
            <Setter Property="Background" Value="#F3F4F6"/>
          </Style>
          <Style TargetType="DataGridCell">
            <Setter Property="Foreground" Value="Black"/>
            <Style.Triggers>
              <Trigger Property="IsSelected" Value="True">
                <Setter Property="Foreground" Value="Black"/>
                <Setter Property="Background" Value="#DDEAFE"/>
              </Trigger>
            </Style.Triggers>
          </Style>
          <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="Black"/>
          </Style>
          <Style TargetType="TextBox">
            <Setter Property="Foreground" Value="Black"/>
          </Style>
        </DataGrid.Resources>

        <DataGrid.Columns>
          <DataGridTextColumn Header="Item"     Binding="{Binding Item}"     Width="2*"/>
          <DataGridTextColumn Header="Required" Binding="{Binding Required}" Width="*"/>
          <DataGridTextColumn Header="Actual"   Binding="{Binding Actual}"   Width="2*"/>
          <DataGridTemplateColumn Header="Status" Width="120">
            <DataGridTemplateColumn.CellTemplate>
              <DataTemplate>
                <Border x:Name="pill" Padding="6" CornerRadius="8">
                  <TextBlock x:Name="label"
                             HorizontalAlignment="Center"
                             FontWeight="Bold"
                             Foreground="White"/>
                </Border>
                <DataTemplate.Triggers>
                  <DataTrigger Binding="{Binding Passed}" Value="True">
                    <Setter TargetName="pill"  Property="Background" Value="#064E3B"/>
                    <Setter TargetName="label" Property="Text"        Value="PASS"/>
                  </DataTrigger>
                  <DataTrigger Binding="{Binding Passed}" Value="False">
                    <Setter TargetName="pill"  Property="Background" Value="#7F1D1D"/>
                    <Setter TargetName="label" Property="Text"        Value="FAIL"/>
                  </DataTrigger>
                </DataTemplate.Triggers>
              </DataTemplate>
            </DataGridTemplateColumn.CellTemplate>
          </DataGridTemplateColumn>
        </DataGrid.Columns>
      </DataGrid>
    </GroupBox>

    <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="BtnRun"    Content="Run Checks"/>
      <Button Name="BtnReport" Content="Preview Report"/>
      <Button Name="BtnSave"   Content="Save Report..."/>
      <Button Name="BtnClose"  Content="Close"/>
    </StackPanel>
  </Grid>
</Window>
"@

# --------------------------
# 5) Load XAML
# --------------------------
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# --------------------------
# 6) Bind controls
# --------------------------
$ReqGrid    = $window.FindName("ReqGrid")
$ResultGrid = $window.FindName("ResultGrid")
$BtnRun     = $window.FindName("BtnRun")
$BtnReport  = $window.FindName("BtnReport")
$BtnSave    = $window.FindName("BtnSave")
$BtnClose   = $window.FindName("BtnClose")

# --------------------------
# 7) Fill requirements grid
# --------------------------
$ReqItems = @()
$Req.GetEnumerator() | ForEach-Object {
  if ($_.Key -eq "Require Tools") {
    $tools = @($_.Value) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $ReqItems += [pscustomobject]@{
      Key   = "Required Tools"
      Value = if ($tools.Count) { $tools -join ", " } else { "None" }
    }
  } else {
    $ReqItems += [pscustomobject]@{ Key = $_.Key; Value = $_.Value }
  }
}
$ReqGrid.ItemsSource = $ReqItems

# --------------------------
# 8) State
# --------------------------
$script:LastCheck  = $null
$script:LastReport = ""

# --------------------------
# 9) Handlers
# --------------------------
$BtnRun.Add_Click({
  $window.Cursor = "Wait"
  try {
    $script:LastCheck = Invoke-Checks
    $ResultGrid.ItemsSource = $script:LastCheck.Rows
    $ResultGrid.Items.Refresh() | Out-Null
    $script:LastReport = New-ReportText $script:LastCheck
    [System.Media.SystemSounds]::Asterisk.Play()
  } finally {
    $window.Cursor = "Arrow"
  }
})

$BtnReport.Add_Click({
  if (-not $script:LastCheck) {
    $script:LastCheck = Invoke-Checks
    $ResultGrid.ItemsSource = $script:LastCheck.Rows
    $ResultGrid.Items.Refresh() | Out-Null
  }
  $script:LastReport = New-ReportText $script:LastCheck

  $dlg = New-Object System.Windows.Window
  $dlg.Title = "AutoPy++ Validation Report (Preview)"
  $dlg.Width = 900; $dlg.Height = 600
  $dlg.WindowStartupLocation = "CenterOwner"; $dlg.Owner = $window
  $tb = New-Object System.Windows.Controls.TextBox
  $tb.Text = $script:LastReport
  $tb.IsReadOnly = $true
  $tb.TextWrapping = "NoWrap"
  $tb.VerticalScrollBarVisibility = "Auto"
  $tb.FontFamily = "Consolas"
  $tb.Background = "#111827"; $tb.Foreground = "#E5E7EB"
  $tb.Margin = 10
  $dlg.Content = $tb
  $dlg.ShowDialog() | Out-Null
})

$BtnSave.Add_Click({
  if ([string]::IsNullOrWhiteSpace($script:LastReport)) {
    if (-not $script:LastCheck) { $script:LastCheck = Invoke-Checks }
    $script:LastReport = New-ReportText $script:LastCheck
  }
  $dlg = New-Object Microsoft.Win32.SaveFileDialog
  $dlg.FileName = "AutoPyPP_SystemReport.txt"
  $dlg.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
  if ($dlg.ShowDialog()) {
    Set-Content -Path $dlg.FileName -Value $script:LastReport -Encoding UTF8
    [System.Windows.MessageBox]::Show("Report saved:`n$($dlg.FileName)","Saved",
      'OK','Information') | Out-Null
  }
})

$BtnClose.Add_Click({ $window.Close() })

# --------------------------
# 10) Run
# --------------------------
$window.ShowDialog() | Out-Null
