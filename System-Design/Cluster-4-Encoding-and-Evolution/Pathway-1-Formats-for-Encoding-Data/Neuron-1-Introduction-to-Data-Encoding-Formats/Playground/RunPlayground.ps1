# ---- Global Variables ----

# Docker image and container names
$imageName = "encoder-playground"
$containerName = "encoder-playground-container"

# Application URL
$appUrl = "http://localhost:8080"

# Maximum time (in seconds) to wait for Docker to start up
$maxWaitTime = 60

# Time (in seconds) between checks for Docker status
$checkInterval = 5

# ---- Helper Functions: Logging Messages to Console ----

function Write-Info {
    Write-Host "[INFO] $args" -ForegroundColor Blue
}

function Write-ErrorMsg {
    Write-Host "[ERROR] $args" -ForegroundColor Red
}

function Write-Success {
    Write-Host "[SUCCESS] $args" -ForegroundColor Green
}

# ---- Function to Check if Docker is Installed and Running ----

function Test-Docker {
    Write-Info "Checking if Docker is installed..."

    # Check if Docker command is available
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-ErrorMsg "Docker is not installed. Please install Docker Desktop and try again."
        exit 1
    } else {
        Write-Success "Docker is installed."
    }

    Write-Info "Checking if Docker is running..."

    # Check if Docker daemon is running
    try {
        docker info | Out-Null
    } catch {
        Write-Info "Docker is not running. Attempting to start Docker Desktop..."

        # Attempt to start Docker Desktop
        Start-Process "Docker Desktop" -ErrorAction SilentlyContinue

        # Wait for Docker to start
        Wait-DockerStart
    }
    Write-Success "Docker is running."
}

# ---- Function to Wait for Docker to Start ----

function Wait-DockerStart {
    Write-Info "Waiting for Docker to start..."

    # Initialize a timer to track elapsed time
    $elapsedTime = 0

    # Loop until Docker is running or timeout is reached
    while ($true) {
        try {
            docker info | Out-Null
            break
        } catch {
            # If the elapsed time exceeds the maximum wait time, exit the script
            if ($elapsedTime -ge $maxWaitTime) {
                Write-ErrorMsg "Docker failed to start after waiting for $maxWaitTime seconds."
                exit 1
            }

            # Wait for the specified interval before checking again
            Start-Sleep -Seconds $checkInterval
            $elapsedTime += $checkInterval

            # Log the retry attempt
            Write-Info "Docker is not running yet. Retrying in $checkInterval seconds..."
        }
    }

    # Once Docker is running, log a success message
    Write-Success "Docker is now running."
}

# ---- Function to Build the Docker Image ----

function Build-Image {
    Write-Info "Building the Docker image '$imageName'..."

    # Check if Dockerfile exists in the current directory
    $dockerfilePath = "./Dockerfile"
    if (!(Test-Path -Path $dockerfilePath)) {
        Write-ErrorMsg "Dockerfile not found at path: $dockerfilePath. Ensure it's in the correct directory."
        exit 1
    }

    # Build the Docker image and handle any errors
    if (!(docker build -t $imageName .)) {
        Write-ErrorMsg "Failed to build Docker image."
        exit 1
    }

    # Log a success message if the image builds successfully
    Write-Success "Docker image '$imageName' built successfully."
}

# ---- Function to Stop and Remove Existing Container ----

function Remove-Container {
    Write-Info "Stopping and removing any existing container named '$containerName'..."

    # Check if the container exists
    if (docker ps -a --format '{{.Names}}' | Select-String "^$containerName$") {
        # Stop and remove the container
        docker stop $containerName | Out-Null
        docker rm $containerName | Out-Null
        Write-Info "Existing container '$containerName' stopped and removed."
    } else {
        # If the container does not exist, log that information
        Write-Info "No existing container named '$containerName' found."
    }
}

# ---- Function to Run the Docker Container ----

function Start-Container {
    Write-Info "Running the Docker container '$containerName'..."

    # Run the container and handle any errors
    if (!(docker run -d -p 8080:8080 --name $containerName $imageName)) {
        Write-ErrorMsg "Failed to run Docker container."
        exit 1
    }

    # Log a success message if the container starts successfully
    Write-Success "Docker container '$containerName' is running."
}

# ---- Function to Open the Web Browser ----

function Open-Browser {
    Write-Info "Opening the web browser to $appUrl..."

    # Use the 'Start-Process' command to open the URL
    Start-Process $appUrl
}

# ---- Main Script Execution ----

Write-Info "Starting the playground setup..."

# Step 1: Check if Docker is installed and running
Test-Docker

# Step 2: Build the Docker image
Build-Image

# Step 3: Stop and remove any existing Docker container
Remove-Container

# Step 4: Run the Docker container
Start-Container

# Step 5: Wait for the container to initialize
Write-Info "Waiting for the container to start..."
Start-Sleep -Seconds 5

# Step 6: Open the application in the default web browser
Open-Browser

# Log a final success message
Write-Success "The playground is running at $appUrl"
