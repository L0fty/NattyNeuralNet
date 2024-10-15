# ---- Helper Functions ----
function Write-LogInfo {
    Write-Host "[INFO] $($args)" -ForegroundColor Cyan
}

function Write-LogError {
    Write-Host "[ERROR] $($args)" -ForegroundColor Red
}

function Write-LogSuccess {
    Write-Host "[SUCCESS] $($args)" -ForegroundColor Green
}

# ---- Function to Test if Running as Administrator ----
function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-LogError "You need to run this script as Administrator."
        exit 1
    }
}

# ---- Function to Enable WSL 2 ----
function Enable-WSL2 {
    Write-LogInfo "Checking if WSL 2 is enabled..."

    # Check if WSL is enabled
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $wslEnabled = $wslFeature.State -eq "Enabled"

    # Check if Virtual Machine Platform is enabled
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    $vmEnabled = $vmFeature.State -eq "Enabled"

    $restartRequired = $false

    # Enable WSL if not enabled
    if (-not $wslEnabled) {
        Write-LogInfo "Enabling WSL feature..."
        $result = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -ErrorAction Stop
        Write-LogSuccess "WSL feature enabled."
        if ($result.RestartNeeded) {
            $restartRequired = $true
        }
    } else {
        Write-LogInfo "WSL feature is already enabled."
    }

    # Enable Virtual Machine Platform if not enabled
    if (-not $vmEnabled) {
        Write-LogInfo "Enabling Virtual Machine Platform feature..."
        $result = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction Stop
        Write-LogSuccess "Virtual Machine Platform feature enabled."
        if ($result.RestartNeeded) {
            $restartRequired = $true
        }
    } else {
        Write-LogInfo "Virtual Machine Platform feature is already enabled."
    }

    # Prompt for Restart if Required
    if ($restartRequired) {
        Write-LogInfo "A system restart is required to complete the WSL 2 installation."
        $restart = Read-Host "Do you want to restart now? (Y/N)"
        if ($restart -match '^[Yy]') {
            Write-LogInfo "Restarting the system..."
            Restart-Computer
        } else {
            Write-LogInfo "Please restart your computer manually before proceeding."
            exit 1
        }
    } else {
        Write-LogInfo "No restart is required."
    }

    # Check if WSL 2 kernel update is installed
    $wslKernelInstalled = $false
    try {
        wsl --status | Out-Null
        $wslKernelInstalled = $true
    } catch {
        $wslKernelInstalled = $false
    }

    if (-not $wslKernelInstalled) {
        Write-LogInfo "Installing WSL 2 Kernel Update..."
        try {
            $wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
            $wslInstaller = "$env:TEMP\wsl_update_x64.msi"

            Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslInstaller -ErrorAction Stop
            Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$wslInstaller`" /quiet /norestart" -Wait -ErrorAction Stop

            Write-LogSuccess "WSL 2 Kernel Update installed successfully."
        } catch {
            Write-LogError "Failed to install WSL 2 Kernel Update. Error details: $_"
            exit 1
        }
    } else {
        Write-LogInfo "WSL 2 Kernel Update is already installed."
    }

    # Set WSL 2 as Default Version
    Write-LogInfo "Setting WSL 2 as the default version..."
    wsl --set-default-version 2
    Write-LogSuccess "WSL 2 is set as the default version."
}

# ---- Function to Install Chocolatey ----
function Install-Chocolatey {
    Write-LogInfo "Checking if Chocolatey is installed..."
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-LogInfo "Chocolatey is not installed. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType] 'Tls12'
        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-LogSuccess "Chocolatey installed successfully."
        } catch {
            Write-LogError "Failed to install Chocolatey."
            exit 1
        }
    } else {
        Write-LogInfo "Chocolatey is already installed."
    }
}

# ---- Function to Install Docker Desktop ----
function Install-DockerDesktop {
    Write-LogInfo "Checking if Docker Desktop is installed..."
    $dockerInstalled = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq "Docker Desktop" }
    if (-not $dockerInstalled) {
        Write-LogInfo "Docker Desktop is not installed. Installing Docker Desktop..."
        try {
            choco install docker-desktop -y --no-progress
            Write-LogSuccess "Docker Desktop installed successfully."
        } catch {
            Write-LogError "Failed to install Docker Desktop."
            exit 1
        }
    } else {
        Write-LogInfo "Docker Desktop is already installed."
    }
}

# ---- Function to Check Group Membership ----
function Test-GroupMembership {
    Write-LogInfo "Checking if group membership changes have taken effect..."

    $groups = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups |
              ForEach-Object { $_.Translate([System.Security.Principal.NTAccount]).Value }

    if ($groups -match 'docker-users') {
        Write-LogSuccess "Group membership changes have taken effect."
    } else {
        Write-LogError "Group membership changes have not taken effect in your current session."
        Write-LogInfo "Please log out of Windows and log back in to apply group membership changes."
        Write-LogInfo "After logging back in, please rerun this script to continue the setup."
        exit 1
    }
}

# ---- Function to Start Docker Desktop ----
function Start-DockerDesktop {
    Write-LogInfo "Starting Docker Desktop..."

    # Possible installation paths
    $possiblePaths = @(
        "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
        "$env:LOCALAPPDATA\Programs\Docker\Docker\Docker Desktop.exe"
    )

    $dockerDesktopPath = $null

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $dockerDesktopPath = $path
            break
        }
    }

    if ($dockerDesktopPath) {
        Start-Process -FilePath $dockerDesktopPath -ErrorAction SilentlyContinue
        Write-LogInfo "Docker Desktop started using '$dockerDesktopPath'."
    } else {
        Write-LogError "Docker Desktop executable not found in default locations."
        exit 1
    }

    # Provide instructions for manual configuration
    Write-LogInfo "Please configure Docker Desktop to use WSL 2 manually:"
    Write-LogInfo "1. Open Docker Desktop."
    Write-LogInfo "2. Click on the gear icon to open Settings."
    Write-LogInfo "3. In the 'General' tab, check 'Use the WSL 2 based engine'."
    Write-LogInfo "4. Go to 'Resources' > 'WSL Integration'."
    Write-LogInfo "5. Enable integration with your installed Linux distribution."
    Write-LogInfo "6. Click 'Apply & Restart'."

    # Wait for the user to complete configuration
    Read-Host "Press Enter to continue after you have configured Docker Desktop to use WSL 2."

    Wait-DockerDesktop
}

# ---- Function to Wait for Docker Desktop to Become Ready ----
function Wait-DockerDesktop {
    Write-LogInfo "Waiting for Docker Desktop to start..."
    $maxWaitTime = 300  # 5 minutes
    $checkInterval = 5
    $elapsedTime = 0

    while ($true) {
        try {
            docker info | Out-Null
            break
        } catch {
            if ($elapsedTime -ge $maxWaitTime) {
                Write-LogError "Docker failed to start after waiting for $maxWaitTime seconds."
                exit 1
            }
            Write-LogInfo "Docker is not running yet. Retrying in $checkInterval seconds..."
            Start-Sleep -Seconds $checkInterval
            $elapsedTime += $checkInterval
        }
    }
    Write-LogSuccess "Docker Desktop is running!"
}

# ---- Function to Verify Docker Installation ----
function Test-DockerInstallation {
    Write-LogInfo "Verifying Docker installation..."
    try {
        docker --version
    } catch {
        Write-LogError "Docker is not installed correctly."
        exit 1
    }
}

# ---- Function to Run Docker Test ----
function Test-DockerRun {
    Write-LogInfo "Running a basic Docker test by pulling the 'hello-world' image..."
    try {
        docker run hello-world
        Write-LogSuccess "Docker is running correctly!"
    } catch {
        Write-LogError "Docker test failed. Please ensure Docker is running and try again."
        exit 1
    }
}

# ---- Main Script Logic ----
Write-LogInfo "Starting Docker installation script for Windows..."

# Check if running as Administrator
Test-Admin

# Enable WSL 2
Enable-WSL2

# Install Chocolatey
Install-Chocolatey

# Install Docker Desktop
Install-DockerDesktop

# Check Group Membership
Test-GroupMembership

# Start Docker Desktop
Start-DockerDesktop

# Verify Docker Installation
Test-DockerInstallation

# Run Docker Test
Test-DockerRun

Write-LogSuccess "Docker setup complete!"
