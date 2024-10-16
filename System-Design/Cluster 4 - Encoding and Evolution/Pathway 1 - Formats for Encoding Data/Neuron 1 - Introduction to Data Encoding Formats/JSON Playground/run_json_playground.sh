#!/bin/bash

# ---- Global Variables ----

# Docker image and container names
IMAGE_NAME="json-playground"
CONTAINER_NAME="json-playground-container"

# Application URL
APP_URL="http://localhost:8080"

# Maximum time (in seconds) to wait for Docker to start up
MAX_WAIT_TIME=60

# Time (in seconds) between checks for Docker status
CHECK_INTERVAL=5

# ---- Helper Functions: Logging Messages to Console ----
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

# ---- Function to Check if Docker is Installed and Running ----
# This function ensures Docker is installed and attempts to start Docker Desktop if it's not running.

check_docker() {
    log_info "Checking if Docker is installed..."

    # Check if the 'docker' command is available
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed. Please install Docker Desktop for macOS and try again."
        exit 1
    else
        log_success "Docker is installed."
    fi

    log_info "Checking if Docker is running..."

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_info "Docker is not running. Attempting to start Docker Desktop..."

        # Attempt to start Docker Desktop
        open -a Docker || {
            # If the command fails, log an error and exit
            log_error "Failed to launch Docker Desktop. Please start it manually."
            exit 1
        }

        # Wait for Docker to start
        wait_for_docker
    else
        log_success "Docker is running."
    fi
}

# ---- Function to Wait for Docker to Start ----
# This function waits until Docker is running or until a timeout is reached.

wait_for_docker() {
    log_info "Waiting for Docker to start..."

    # Initialize a timer to track elapsed time
    elapsed_time=0

    # Loop until Docker is running or timeout is reached
    while ! docker info >/dev/null 2>&1; do
        # If the elapsed time exceeds the maximum wait time, exit the script
        if [ "$elapsed_time" -ge "$MAX_WAIT_TIME" ]; then
            log_error "Docker failed to start after waiting for $MAX_WAIT_TIME seconds."
            exit 1
        fi

        # Wait for the specified interval before checking again
        sleep "$CHECK_INTERVAL"
        elapsed_time=$((elapsed_time + CHECK_INTERVAL))

        # Log the retry attempt
        log_info "Docker is not running yet. Retrying in $CHECK_INTERVAL seconds..."
    done

    # Once Docker is running, log a success message
    log_success "Docker is now running."
}

# ---- Function to Build the Docker Image ----
# This function builds the Docker image using the Dockerfile in the current directory.

build_image() {
    log_info "Building the Docker image '$IMAGE_NAME'..."

    # Build the Docker image and handle any errors
    docker build -t "$IMAGE_NAME" . || {
        log_error "Failed to build Docker image."
        exit 1
    }

    # Log a success message if the image builds successfully
    log_success "Docker image '$IMAGE_NAME' built successfully."
}

# ---- Function to Stop and Remove Existing Container ----
# This function stops and removes any existing container with the specified name.

cleanup_container() {
    log_info "Stopping and removing any existing container named '$CONTAINER_NAME'..."

    # Check if the container exists
    if docker ps -a --format '{{.Names}}' | grep -Eq "^$CONTAINER_NAME\$"; then
        # Stop and remove the container
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 && docker rm "$CONTAINER_NAME" >/dev/null 2>&1
        log_info "Existing container '$CONTAINER_NAME' stopped and removed."
    else
        # If the container does not exist, log that information
        log_info "No existing container named '$CONTAINER_NAME' found."
    fi
}

# ---- Function to Run the Docker Container ----
# This function runs the Docker container in detached mode, mapping the required port.

run_container() {
    log_info "Running the Docker container '$CONTAINER_NAME'..."

    # Run the container and handle any errors
    docker run -d -p 8080:8080 --name "$CONTAINER_NAME" "$IMAGE_NAME" || {
        log_error "Failed to run Docker container."
        exit 1
    }

    # Log a success message if the container starts successfully
    log_success "Docker container '$CONTAINER_NAME' is running."
}

# ---- Function to Open the Web Browser ----
# This function opens the application URL in the default web browser.

open_browser() {
    log_info "Opening the web browser to $APP_URL..."

    # Use the 'open' command to open the URL
    open "$APP_URL" || {
        # If opening the browser fails, inform the user
        log_error "Failed to open web browser. Please navigate to $APP_URL manually."
    }
}

# ---- Main Script Execution ----
# The main part of the script orchestrates the setup process.

log_info "Starting the application setup..."

# Step 1: Check if Docker is installed and running
check_docker

# Step 2: Build the Docker image
build_image

# Step 3: Stop and remove any existing Docker container
cleanup_container

# Step 4: Run the Docker container
run_container

# Step 5: Wait for the container to initialize
log_info "Waiting for the container to start..."
sleep 5

# Step 6: Open the application in the default web browser
open_browser

# Log a final success message
log_success "Application is running at $APP_URL"