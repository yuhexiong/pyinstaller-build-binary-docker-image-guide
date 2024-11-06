# Step 1: Build stage - Install dependencies and build the executable
FROM python:3.9-slim AS builder

# Update package list and install essential build dependencies and client libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    binutils \
    pkg-config \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory to /app
WORKDIR /app

# Copy all application files
COPY . .

# Install required Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Install PyInstaller for bundling the app
RUN pip install pyinstaller

# Use PyInstaller to create a single executable with all dependencies included
RUN pyinstaller --onefile -n {EXECUTABLE_FILE_NAME} --collect-all {MODULE} {ENTRY_FILE}.py

# Step 2: Final stage - Copy executable into a minimal image
FROM python:3.9-slim

# Copy the executable from the builder stage
COPY --from=builder /app/dist/{EXECUTABLE_FILE_NAME} /app/{EXECUTABLE_FILE_NAME}

# Set the working directory and specify entrypoint
WORKDIR /app
CMD ["./{EXECUTABLE_FILE_NAME}", "runserver", "0.0.0.0:8000", "--noreload"]