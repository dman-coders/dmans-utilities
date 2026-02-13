# Jellyfin Integration Utilities

A collection of scripts and tools for automating media library management between the local `media_library` tag system and Jellyfin (a self-hosted media server). The goal is to keep collections, tags, and metadata synchronized without manual intervention.

**Key scripts:** `JellyFin` (main orchestrator), `ListCollections`, `CreateCollection`, `MediaFolders`, `Genres`, plus utility functions in `jellyfin-utils.lib`.

See `README-utilities.md` for detailed documentation of available scripts, API findings, and next steps for completing the integration toolkit.

## Testing

The testing infrastructure is still in active development. To run tests and explore the current state:

```bash
cd Jellyfin
./test.sh
```

Refer to `test.sh` for the current test scenarios and to understand the integration testing approach. The test suite will evolve as new utility scripts are implemented.

## API Reference

Jellyfin API documentation is available at:
```
http://$JELLYFIN_HOST:$JELLYFIN_PORT/api-docs/swagger/index.html
```

Example: `http://granite.local:8096/api-docs/swagger/index.html`
