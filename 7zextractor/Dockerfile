FROM alpine:latest

# Update and install 7zip
RUN apk update && \
    apk add --no-cache p7zip

# Create a working directory
WORKDIR /data

ENTRYPOINT ["7z", "x"]
# Default arguments can be overridden at runtime
CMD [""]