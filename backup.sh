#!/bin/bash
#
# Restic Backup Script
#
# This script is designed to perform backups using Restic.
# It supports various operations such as backup, check, list, prune,
# restore, repair, and unlock.
# It also allows for configuration through environment variables and command-line arguments.
#
# The following environment variables should be set in a .env file:
# - RESTIC_REPOSITORY: The location of the restic repository (e.g., sftp://user@host:/path/to/repo)
# - RESTIC_PASSWORD_FILE: The path to the file containing the restic password
# - SFTP_HOST: The SFTP host for remote backups
# - SFTP_BASEDIR: The base directory for the SFTP backup
# - RESTIC_USER: The username for the SFTP connection
# - MOUNT_POINT: The local mount point when using an external disk
# - FILES: The path to the file containing the list of files to back up
# - EXCLUDES: The path to the file containing the list of files to exclude from the backup
# - GLOBAL_FLAGS: Additional flags for restic commands
# - REPO_NAME: The name of the backup repository
#
set -e


######## START CONFIG ########
REPO_NAME="my-backup"
GLOBAL_FLAGS="--verbose=2"
FILES="${HOME}/.restic/files.txt"
EXCLUDES="${HOME}/.restic/excludes.txt"
######## END CONFIG ########

# Overwriteenvironment variables
. "$HOME/.restic//.env"

function usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help        Show this help message"
  echo "  -b, --backup      Perform backup"
  echo "  -c, --check       Check repository"
  echo "  -i, --info        Get repository stats"
  echo "  -l, --list        List files in the repository"
  echo "  -p, --prune       Prune unwanted data"
  echo "  -r, --restore     Restore files from the repository"
  echo "  -f, --repair      Repair / fix the repository"
  echo "  -u, --unlock      Unlock the repository"
  echo "  -s, --snapshots   List snapshots"
}

function parse_args() {
  if [ "$#" -eq 0 ]; then
    echo "No arguments provided. Defaulting to backup mode."
    set -- "--backup"
  fi
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -h|--help) usage; exit 0 ;;
      -b|--backup) perform_backup ;;
      -c|--check) check  ;;
      -i|--info) info  ;;
      -l|--list) list-files ;;
      -p|--prune) prune ;;
      -r|--restore) restore ;;
      -f|--repair) repair ;;
      -u|--unlock) unlock ;;
      -s|--snapshots) snapshots ;;
      *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

function cleanup() {
  # clean up old snapshots
  echo "Cleaning up old snapshots..."
  restic "${GLOBAL_FLAGS}" forget -d 7 -w 4 -m 6 -y 2 --prune
}

function check() {
  echo "Performing backup check ..."
  if [ ! "$(restic ${GLOBAL_FLAGS} check)" ]; then
    echo "Repository check failed. Exiting."
    exit 1
  fi
}

function info() {
  echo "Getting repository stats ..."
  if [ ! "$(restic ${GLOBAL_FLAGS} stats)" ]; then
    echo "Getting repository stats failed. Exiting."
    exit 1
  fi
}

function prepare_repo() {
  echo "Test if ${RESTIC_REPOSITORY} exists"
  if [ ! "$(restic snapshots)" ]; then
    echo "Initializing restic repository ..."
    restic init
  else
    echo "Performing pre-backup check ..."
    check
  fi
}

function backup() {
  # perform backups
  echo "Performing backups..."
  restic "${GLOBAL_FLAGS}" backup --files-from "${FILES}" --exclude-file "${EXCLUDES}"
}

function snapshots() {
  echo "Listing restic snapshots ..."
  restic snapshots -c
}

function list-files() {
  echo "Listing files in restic repository ..."
  restic ls latest
}

function prune() {
  echo "Pruning old snapshots ..."
  restic "${GLOBAL_FLAGS}" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 2 --prune
}

function unlock() {
  echo "Unlocking restic repository ..."
  restic "${GLOBAL_FLAGS}" unlock
}

function repair() {
  echo "Repairing restic repository ..."
  restic "${GLOBAL_FLAGS}" check --read-data
}

function restore() {
  echo "Restoring files from restic repository ..."
  restic "${GLOBAL_FLAGS}" restore latest --target /tmp/restic_restore
}
function perform_backup() {
  echo "Starting backup process at $(date '+%Y-%m-%d %H:%M:%S')."

  # init and pre-backup check
  echo "Performing pre-backup check..."
  prepare_repo

  # perform backups
  backup

  # post-backup check
  echo "Performing post backup check..."
  check

  # clean up old snapshots
  echo "Performing housekeeping and clean-up old snapshots..."
  cleanup

  # final check
  echo "Performing final backup check..."
  check

  echo "Backups completed at $(date '+%Y-%m-%d %H:%M:%S')."
}

# Set config options
if [[ -n "${SFTP_HOST}" && -n "${SFTP_BASEDIR}" && -n "${RESTIC_USER}" ]]; then
  echo "Backup to SFTP endpoint ${SFTP_HOST}."
  export RESTIC_REPOSITORY="sftp:${RESTIC_USER}@${SFTP_HOST}:${SFTP_BASEDIR}/${REPO_NAME}"
  export RESTIC_PASSWORD_FILE=/Users/claus/.restic/.store_remote
elif [ -d "${MOUNT_POINT}" ]; then
  echo "Backup to local mount point ${MOUNT_POINT}."
  export RESTIC_REPOSITORY="${MOUNT_POINT}/restic/${REPO_NAME}"
  export RESTIC_PASSWORD_FILE=/Users/claus/.restic/.store_local
else
  echo "SFTP configuration or mount point ${MOUNT_POINT} does not exist. Exiting."
  exit 1
fi

# DEBUG
# env | sort

parse_args "$@"

exit 0
