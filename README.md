# Restic Backup Script

This script is designed to perform backups using Restic.
It supports various operations such as backup, check, list, prune,
restore, repair, and unlock.

It also allows for configuration through environment variables and command-line arguments.

## Configuration

The following environment variables should be set in a .env file:

- RESTIC_REPOSITORY: The location of the restic repository (e.g., sftp://user@host:/path/to/repo)
- RESTIC_PASSWORD_FILE: The path to the file containing the restic password
- SFTP_HOST: The SFTP host for remote backups
- SFTP_BASEDIR: The base directory for the SFTP backup
- RESTIC_USER: The username for the SFTP connection
- MOUNT_POINT: The local mount point when using an external disk
- FILES: The path to the file containing the list of files to back up
- EXCLUDES: The path to the file containing the list of files to exclude from the backup
- GLOBAL_FLAGS: Additional flags for restic commands
- REPO_NAME: The name of the backup repository

The passwords should be in the .store or .store_remote files. Please set the permissions to 400 after setting the password.

## Backup to SFTP

The account running the command should have access to the remote SFTP server via a ssh key. If running the script via cron that key shouldn't have a passphrase.
