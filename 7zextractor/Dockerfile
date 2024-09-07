FROM alpine:latest

# Update and install 7zip
RUN apk update && \
    apk add --no-cache p7zip

# Create a working directory
WORKDIR /data

# Specify the command to run when the container starts
# Use environment variables for the .7z file and target folder
CMD ["sh", "-c", "7z x $ARCHIVE_FILE -o$TARGET_FOLDER"]