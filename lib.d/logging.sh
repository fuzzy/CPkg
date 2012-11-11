logfile_msg() {
  echo "[$(date) ${1}]: ${2}" >> ${CPKG[LOGFILE]}
}

log_info() {
  logfile_msg 'INFO' ${*}
  if [ "${CPKG_VERBOSE}" = "1" ]; then
    echo -e "\033[1;32m+++\033[0;0m ${*}"
  fi
}

log_warn() {
  logfile_msg 'WARN' ${*}
  echo -e "\033[0;33m***\033[0;0m ${*}"
}

log_error() {
  logfile_msg 'ERROR' ${*}
  echo -e "\033[0;31m!!!\033[0;0m ${*}"
}

log_fatal() {
  logfile_msg 'FATAL' "${*}"
  echo -e "\033[1;31m!!!\033[0;0m ${*}"
}

log_debug() {
  logfile_msg 'DEBUG' "${*}"
  if [ "${CPKG_DEBUG}" = "1" ]; then
    echo -e "\033[0;36m%%%\033[0;0m ${*}"
  fi
}
