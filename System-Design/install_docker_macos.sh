#!/bin/bash

# ---- Global Variables ----

# Commands to check Docker's version and status.
DOCKER_VERSION_COMMAND="docker --version"
DOCKER_INFO_COMMAND="docker info"

# Maximum time (in seconds) to wait for Docker to start up.
MAX_WAIT_TIME=120  

# Time (in seconds) between checks for Docker status.
CHECK_INTERVAL=5   

# ---- Helper Function: Logging Messages to Console ----
# These functions display messages with different colors to differentiate between info, errors, and success messages.

log_info() {
    # Print an informational message in blue text.
    echo -e "\033[1;34m[INFO]\033[0m $1"  
}

log_error() {
    # Print an error message in red text.
    echo -e "\033[1;31m[ERROR]\033[0m $1"  
}

log_success() {
    # Print a success message in green text.
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"  
}

# ---- Function to check if Docker Desktop is running ----
# This function will keep checking if Docker is running. If it's not running, it will wait until Docker is ready or a timeout is reached.

wait_for_docker() {
    log_info "Checking if Docker is running..."

    # Initialize a timer to track elapsed time
    elapsed_time=0

    # This loop continuously checks if Docker is running by using the 'docker info' command.
    while ! $DOCKER_INFO_COMMAND >/dev/null 2>&1; do
        # If the elapsed time exceeds the maximum wait time, display an error and exit the script.
        if [ "$elapsed_time" -ge "$MAX_WAIT_TIME" ]; then
            log_error "Docker failed to start after waiting for $MAX_WAIT_TIME seconds."
            exit 1
        fi

        # If Docker is not ready yet, log an info message, wait for CHECK_INTERVAL seconds, and try again.
        log_info "Docker is not running yet. Retrying in $CHECK_INTERVAL seconds..."
        sleep "$CHECK_INTERVAL"
        elapsed_time=$((elapsed_time + CHECK_INTERVAL))
    done

    # If the loop exits, Docker is running, and we log a success message.
    log_success "Docker Desktop is running!"
}

# ---- Function to check if Docker Desktop needs to be launched ----
# This function will launch Docker Desktop if it's not already running.

launch_docker_if_needed() {
    # Check if Docker is already running by using the 'docker info' command.
    if $DOCKER_INFO_COMMAND >/dev/null 2>&1; then
        log_info "Docker is already running. No need to launch Docker Desktop."
    else
        # If Docker is not running, attempt to launch Docker Desktop.
        log_info "Docker is not running. Launching Docker Desktop..."
        open -a Docker || {
            # If the command to open Docker fails, display an error and exit the script.
            log_error "Failed to launch Docker Desktop. Please open it manually."
            exit 1
        }

        # Wait for Docker Desktop to start using the wait_for_docker function.
        wait_for_docker
    fi
}

# ---- Function to verify Docker installation ----
# This function ensures Docker is installed and running. It launches Docker if needed and prints the Docker version.

verify_docker_installation() {
    log_info "Verifying Docker installation..."

    # Ensure Docker Desktop is running before proceeding.
    launch_docker_if_needed

    # Once Docker is running, display the Docker version by running the 'docker --version' command.
    docker --version
}

# ---- macOS Installation Process ----
# This function handles the installation of Docker on macOS using Homebrew.

install_docker_macos() {
    log_info "Preparing to install Docker on macOS using Homebrew..."

    # Step 1: Check if Homebrew is installed by looking for the 'brew' command.
    if ! [ -x "$(command -v brew)" ]; then
        log_info "Homebrew is not installed. Installing Homebrew..."
        
        # If Homebrew is not found, install it using the official Homebrew installation script.
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            log_error "Failed to install Homebrew. Please check your network and try again."
            exit 1
        }

        # If Homebrew is successfully installed, log a success message.
        log_success "Homebrew installed successfully."
    else
        # If Homebrew is already installed, log that information.
        log_info "Homebrew is already installed."
    fi

    # Step 2: Check if Docker Desktop is already installed by verifying if the Docker.app exists in the Applications folder.
    if [ -d "/Applications/Docker.app" ]; then
        log_info "Docker Desktop is already installed."
    else
        # Step 3: If Docker is not installed, install Docker using Homebrew.
        log_info "Installing Docker using Homebrew..."
        brew install --cask docker || {
            # If the installation fails, log an error and exit the script.
            log_error "Failed to install Docker. Please try again."
            exit 1
        }

        # Log a success message once Docker is installed.
        log_success "Docker installed successfully. Please follow any on-screen instructions to finish the setup."
    fi
}

# ---- Post-installation Docker Test ----
# This function runs a simple test to verify that Docker is working by running the 'hello-world' Docker image.

docker_test_run() {
    log_info "Running a basic Docker test by pulling the 'hello-world' image..."

    # Run the 'hello-world' container to check if Docker is working properly.
    docker run hello-world || {
        # If the test fails, log an error and exit the script.
        log_error "Docker test failed. Please ensure Docker is running and try again."
        exit 1
    }

    # If the test is successful, log a success message.
    log_success "Docker is running correctly!"
}

# ---- Main Script Logic ----
# The main part of the script that orchestrates the installation and setup process.

log_info "Starting Docker installation script..."

# Step 1: Detect the operating system using the 'uname -s' command.
OS=$(uname -s)

# If the OS is detected as 'Darwin', it's macOS, and we proceed with macOS-specific steps.
case "$OS" in
    Darwin*)
        OS="MacOS"
        ;;
    *)
        # If the OS is not macOS, log an error and exit, as this script only supports macOS.
        log_error "Unsupported OS: $OS. This script is intended for macOS."
        exit 1
        ;;
esac

# Step 2: Handle installation for macOS.
if [ "$OS" = "MacOS" ]; then
    # Check if Docker is already installed by looking for the 'docker' command.
    if ! [ -x "$(command -v docker)" ]; then
        log_info "Docker is not installed. Proceeding with installation..."
        install_docker_macos
    else
        # If Docker is already installed, log a success message.
        log_success "Docker is already installed on your system."
    fi

    # Step 3: Verify Docker installation and ensure Docker Desktop is running.
    verify_docker_installation

    # Step 4: Run a test to ensure Docker is functioning properly.
    docker_test_run

    # If everything completes successfully, log a final success message.
    log_success "Docker setup complete!"
fi