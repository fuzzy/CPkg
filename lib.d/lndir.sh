slndir() {
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo 'Usage: slndir /dir1 /dir2/'
  else
    SRC=${1}
    if [ "${2}" = "." ] || [ "${2}" = "./" ]; then
      DST=${PWD}
    else
      DST=${2}
    fi
    tmp=$(mktemp /tmp/cpkg.${RND})
    echo ${PWD} > ${tmp}
    cd ${SRC}
    for itm in $(ls); do
      if [ -x ${DST}/${itm} ] && [ -d ${DST}/${itm} ]; then
        `slndir ${SRC}/${itm} ${DST}/${itm}`
      elif [ -d ${SRC}/${itm} ]; then
        mkdir -p ${DST}/${itm}
        `slndir ${SRC}/${itm} ${DST}/${itm}`
      else
        $(which ln) -s ${SRC}/${itm} ${DST}/${itm} 2>/dev/null
      fi
    done
    cd $(cat ${tmp})
    rm -f ${tmp}
  fi
}
