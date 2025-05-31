#!/bin/bash

# ChatGPT Wrote This.

# === Configuration ===
CONTAINERS=(
  immich_postgres immich_redis immich_server
  paperless_db paperless_redis paperless_webserver
  seafile seafile-memcached seafile-mysql
  plex sonarr radarr jackett flaresolverr ombi
  readeck linkding
)

LOCAL_DIR="/home/carson/webapps"
BACKUP_DIR_LOCAL="/home/carson/Synology/webapp_backups/webapps_local"

LOGFILE="/home/carson/backup_and_restart.log"

DRY_RUN=false

# === Parse Arguments ===
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# === Functions ===
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

stop_containers() {
  log "Stopping containers..."
  for container in "${CONTAINERS[@]}"; do
    docker stop "$container" && log "Stopped $container" || log "Failed to stop $container"
  done
}

start_containers() {
  log "Starting containers..."
  for container in "${CONTAINERS[@]}"; do
    docker start "$container" && log "Started $container" || log "Failed to start $container"
  done
}

perform_backups() {
  RSYNC_FLAGS="-a --delete --progress"
  if $DRY_RUN; then
    RSYNC_FLAGS+=" --dry-run"
    log "Dry-run mode active: No files will be copied or deleted."
  fi

  log "Backing up local webapps..."
  rsync $RSYNC_FLAGS "$LOCAL_DIR/" "$BACKUP_DIR_LOCAL/" 2>&1 | tee -a "$LOGFILE"
  log "Backup of local directory completed."
}

# === Main Execution ===
log "Backup job started."
if $DRY_RUN; then
  log "Running in dry-run mode."
fi

stop_containers
perform_backups
start_containers

log "Backup job completed."
log "-----------------------------"