# Locust Security Notes

## Tokens

Locust accepts a GitHub access token through the editor UI and keeps it in memory for the current editor session. It is not written to `.locust/config.json`.

Use the minimum GitHub permissions required for the repositories you want Locust to manage. Never commit a token to the project.

## Project files

Locust ignores its own `.locust` working directory, Godot generated directories, temporary files and logs by default. Review the ignore list before syncing a project that contains sensitive files.

## Repository access

Locust uses HTTPS requests to `api.github.com`. Repository access is controlled by GitHub permissions. Locust does not bypass GitHub repository permissions.

## Recovery

Before automatic file changes, Locust attempts to create a local backup. Recovery files are local project data and should not be committed unless the team explicitly wants them.
