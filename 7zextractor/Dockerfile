FROM alpine:latest

# Update and install 7zip
RUN apk update && \
    apk add --no-cache p7zip

# Create a working directory
WORKDIR /data

# Default arguments can be overridden at runtime
CMD ["7z", "x"]