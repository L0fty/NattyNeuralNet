# DockerInstallWindows.ps1

# ---- Helper Functions ----
function Log-Info {
    Write-Host "[INFO] $($args)" -ForegroundColor Cyan
}

function Log-Error {
    Write-Host "[ERROR] $($args)" -ForegroundColor Red
}

function Log-Success {
    Write-Host "[SUCCESS] $($args)" -ForegroundColor Green
}

# ---- Function to Check if Running as Administrator ----
function Check-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Log-Error "You need to run this script as Administrator."
        exit 1
    }
}

# ---- Function to Install Chocolatey ----
function Install-Chocolatey {
    Log-Info "Checking if Chocolatey is installed..."
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Log-Info "Chocolatey is not installed. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) || {
            Log-Error "Failed to install Chocolatey."
            exit 1
        }
        Log-Success "Chocolatey installed successfully."
    } else
        {
        Log-Info "Chocolatey is already installed."
    }
}

# ---- Function to Install Docker Desktop ----
function Install-DockerDesktop {
    Log-Info "Checking if Docker Desktop is installed..."
    $dockerInstalled = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq "Docker Desktop" }
    if (-not $dockerInstalled) {
        Log-Info "Docker Desktop is not installed. Installing Docker Desktop..."
        choco install docker-desktop -y || {
            Log-Error "Failed to install Docker Desktop."
            exit 1
        }
        Log-Success "Docker Desktop installed successfully."
    } else {
        Log-Info "Docker Desktop is already installed."
    }
}

# ---- Function to Start Docker Desktop ----
function Start-DockerDesktop {
    Log-Info "Starting Docker Desktop..."
    Start-Process -FilePath "Docker Desktop" -ErrorAction SilentlyContinue
    Wait-DockerDesktop
}

# ---- Function to Wait for Docker Desktop to Become Ready ----
function Wait-DockerDesktop {
    Log-Info "Waiting for Docker Desktop to start..."
    $maxWaitTime = 300  # Increased wait time for Windows
    $checkInterval = 5
    $elapsedTime = 0

    while ($true) {
        try {
            docker info | Out-Null
            break
        } catch {
            if ($elapsedTime -ge $maxWaitTime) {
                Log-Error "Docker failed to start after waiting for $maxWaitTime seconds."
                exit 1
            }
            Log-Info "Docker is not running yet. Retrying in $checkInterval seconds..."
            Start-Sleep -Seconds $checkInterval
            $elapsedTime += $checkInterval
        }
    }
    Log-Success "Docker Desktop is running!"
}

# ---- Function to Verify Docker Installation ----
function Verify-DockerInstallation {
    Log-Info "Verifying Docker installation..."
    try {
        docker --version
    } catch {
        Log-Error "Docker is not installed correctly."
        exit 1
    }
}

# ---- Function to Run Docker Test ----
function Docker-TestRun {
    Log-Info "Running a basic Docker test by pulling the 'hello-world' image..."
    try {
        docker run hello-world
        Log-Success "Docker is running correctly!"
    } catch {
        Log-Error "Docker test failed. Please ensure Docker is running and try again."
        exit 1
    }
}

# ---- Main Script Logic ----
Log-Info "Starting Docker installation script for Windows..."

# Check if running as Administrator
Check-Admin

# Install Chocolatey
Install-Chocolatey

# Install Docker Desktop
Install-DockerDesktop

# Start Docker Desktop
Start-DockerDesktop

# Verify Docker Installation
Verify-DockerInstallation

# Run Docker Test
Docker-TestRun

Log-Success "Docker setup complete!"