cpkg_belongs_to() {
  if [ ! -z "$(grep ${1} ${CPKG[GLOBAL]}/.packages)" ]; then
  	echo '\033[1;32mG\033[0;0m'
  elif [ ! -z "$(grep ${1} ${CPKG[SESSION]}/.packages)" ]; then
  	echo '\033[0;36mS\033[0;0m'
  else
  	echo ' '
  fi
}

cpkg_in_use() {
  GLB=${CPKG[GLOBAL]}/.packages
  SSN=${CPKG[SESSION]}/.packages
  if [ ! -z "$(grep ${1} ${GLB} ${SSN})" ]; then
    echo 1
  else
    echo 0
  fi
}
