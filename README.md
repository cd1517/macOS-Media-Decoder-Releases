# macOS Media Decoder Releases

This public repository contains optional, architecture-specific media decoder components for macOS.

- The host app does not bundle these binaries.
- A download starts only after the user explicitly confirms installation.
- Each release includes its upstream licenses and is verified by exact size and SHA-256 before installation.
- Apple Silicon and Intel Macs download separate archives.

The component is built from pinned official mpv sources and can be shared by multiple enabled media formats. It reads media files directly and does not create a compatible copy for every video.
