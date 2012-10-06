logfile_msg() {
  echo "[$(date) ${1}]: ${2}" >> ${CPKG[LOGFILE]}
}

logoutput_msg() {
  echo -e "[${1}]: ${2}"
}

log_info() {
  logfile_msg 'INFO' ${*}
  logoutput_msg '\033[1;32m++\033[0;0m' ${*}
}

log_warn() {
  logfile_msg 'WARN' ${*}
  logoutput_msg '\033[0;33m**\033[0;0m' ${*}
}

log_error() {
  logfile_msg 'ERROR' ${*}
  logoutput_msg '\033[0;31m!!\033[0;0m' ${*}
}

log_fatal() {
  logfile_msg 'FATAL' ${*}
  logoutput_msg '\033[1;31m!!\033[0;0m' ${*}
}

log_debug() {
  logfile_msg 'DEBUG' ${*}
  logoutput_msg '\033[0;36m%%\033[0;0m' ${*}
}
