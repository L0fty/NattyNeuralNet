#!/bin/bash
# Enable strict error handling:
#   -e: Exit immediately if any command fails.
#   -u: Treat unset variables as errors.
#   -o pipefail: Return the exit status of the first failed command in a pipeline.
set -euo pipefail

# ============================================================
# CONFIGURATION VARIABLES
# ============================================================
# Modify these values as needed.
OS_REQUIRED="Darwin"    # The OS expected (Darwin means macOS)
MAX_WAIT_TIME=120       # Maximum seconds to wait for Docker to start
CHECK_INTERVAL=5        # Seconds between Docker status checks

# ============================================================
# LOGGING FUNCTIONS
# ============================================================
# These functions provide structured logging with color coding for better visibility.

# Logs an informational message in blue
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $*"
}

# Logs an error message in red
log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $*"
}

# Logs a success message in green
log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $*"
}

# ============================================================
# FUNCTION: check_os
# ============================================================
# Ensures that the script is running on macOS.
check_os() {
    local os
    os=$(uname -s)  # Get the operating system name
    if [[ "$os" != "$OS_REQUIRED" ]]; then  # Compare with expected OS
        log_error "This script is intended for macOS. Detected OS: $os"
        exit 1  # Exit if the OS is not macOS
    fi
    log_info "Operating system check passed: $os"
}

# ============================================================
# FUNCTION: ensure_homebrew
# ============================================================
# Checks if Homebrew is installed; if not, installs it. If installed, updates it.
ensure_homebrew() {
    if ! command -v brew >/dev/null; then  # Check if 'brew' command is available
        log_info "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  # Install Homebrew
        log_success "Homebrew installed."
    else
        log_info "Homebrew is already installed. Updating Homebrew..."
        brew update  # Update Homebrew to ensure the latest package availability
    fi
}

# ============================================================
# FUNCTION: install_docker
# ============================================================
# Uses Homebrew to install Docker Desktop if it's not already installed.
install_docker() {
    if brew list --cask --versions docker >/dev/null 2>&1; then  # Check if Docker is installed
        log_info "Docker Desktop is already installed."
    else
        log_info "Installing Docker Desktop via Homebrew..."
        brew install --cask docker  # Install Docker using Homebrew Cask
        log_success "Docker Desktop installation initiated. Follow on-screen instructions if prompted."
    fi
}

# ============================================================
# FUNCTION: wait_for_docker
# ============================================================
# Waits for Docker to become responsive by repeatedly checking its status.
wait_for_docker() {
    log_info "Waiting for Docker to become available..."
    local elapsed=0  # Initialize elapsed time counter

    until docker info >/dev/null 2>&1; do  # Keep checking until Docker responds
        if (( elapsed >= MAX_WAIT_TIME )); then  # If timeout is reached, exit with an error
            log_error "Docker did not start within ${MAX_WAIT_TIME} seconds."
            exit 1
        fi
        sleep "$CHECK_INTERVAL"  # Wait before retrying
        elapsed=$(( elapsed + CHECK_INTERVAL ))  # Increment elapsed time
        log_info "Still waiting for Docker... ($elapsed seconds elapsed)"
    done

    log_success "Docker is now running."
}

# ============================================================
# FUNCTION: launch_docker
# ============================================================
# Attempts to start Docker Desktop if it isn't already running.
launch_docker() {
    if docker info >/dev/null 2>&1; then  # Check if Docker is already running
        log_info "Docker is already running."
    else
        log_info "Starting Docker Desktop..."
        open -a Docker || {  # Attempt to open Docker Desktop application
            log_error "Failed to launch Docker Desktop. Please start it manually."
            exit 1  # Exit if Docker couldn't be launched
        }
        wait_for_docker  # Wait for Docker to become responsive
    fi
}

# ============================================================
# FUNCTION: docker_test
# ============================================================
# Runs a basic Docker test to verify installation and functionality.
docker_test() {
    log_info "Running Docker 'hello-world' test..."
    docker run --rm hello-world || {  # Run the hello-world container and remove it after execution
        log_error "Docker test failed. Please ensure Docker is running correctly."
        exit 1
    }
    log_success "Docker test completed successfully."
}

# ============================================================
# MAIN FUNCTION
# ============================================================
# This function orchestrates all the setup steps.
main() {
    # Step 1: Check that we're running on macOS.
    check_os

    # Step 2: Ensure Homebrew is installed and updated.
    ensure_homebrew

    # Step 3: Install Docker Desktop via Homebrew (if not already installed).
    install_docker

    # Step 4: Confirm that the 'docker' command is available.
    if ! command -v docker >/dev/null; then
        log_error "Docker command not found. Ensure Docker Desktop is installed and properly configured."
        exit 1
    fi

    # Step 5: Launch Docker Desktop if it's not already running.
    launch_docker

    # Step 6: Run a test container to verify Docker works.
    docker_test

    log_success "Docker setup is complete!"
}

# Run the main function with any arguments passed to the script.
main "$@"