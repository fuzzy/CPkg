#!/usr/bin/env bash

source ~/.cpkg/cpkg.sh

# fetch
cfetch() {
	if [ ! -z "${*}" ]; then
		${CPKG[CMD_FETCH]} $*
	else
		log_error "You must supply a valid URI."
	fi
}

# extract
cextract() {
	if [ ! -f ${1} ]; then
		log_error "You must supply a valid filename."
	else
		log_info "Extracting $(basename ${1})"
		cur_path=${PWD}
		tmp_path=$(echo ${1}|sed -e "s,$(basename ${1}),,g")
		cd ${tmp_path}
		if [ ! -z "$(file ${1}|grep gzip)" ]; then
			tar -zxf ${1}
		elif [ ! -z "$(file ${1}|grep xz)" ]; then
			tar -zxf ${1}
		elif [ ! -z "$(file ${1}|grep bzip2)" ]; then
			tar -jxf ${1}
		fi
		cd ${cur_path}
		unset tmp_path && unset cur_path
	fi
}

# config
cconfigure() {
	log_info "Configuring $(basename ${PWD})"
	./configure --prefix=${CPKG[PKG_DIR]}/${CPKG[OS_STAMP]}$(basename $(pwd)|tr "[:upper:]" "[:lower:]") ${*} 2>${CPKG[LOG_DIR]}/$(basename ${PWD})-error.log 1>${CPKG[LOG_DIR]}/$(basename ${PWD}).log
}

# install
cinstall() {
	case "$(uname -s)" in
		SunOS) NCPU=$($(which kstat) -m cpu_info|grep core_id|grep -v pkg|wc -l) ;;
	esac
	log_info "Building $(basename ${PWD})"
	make -j ${NJOBS:-3} 2>${CPKG[LOG_DIR]}/$(basename ${PWD})-error.log 1>${CPKG[LOG_DIR]}/$(basename ${PWD}).log
	log_info "Installing $(basename ${PWD})"
	make install 2>${CPKG[LOG_DIR]}/$(basename ${PWD})-error.log 1>${CPKG[LOG_DIR]}/$(basename ${PWD}).log
}

# dependancy (note there is no dependancy resolution at this point, you must order them properly yourself)
cdepend() {
	if [ ! -z "${1}" ]; then
		${CPKG[CMD_BUILDER]} ${1}
	fi
}

if [ -z "${1}" ]; then
	if [ ! -f ${CPKG[PKGSCRIPT]}/${1}.sh ]; then
		log_error "The specified pkgscript does not exist: ${1}"
	else
		START_DIR=${PWD}
		source ${CPKG[PKGSCRIPT]}/${1}.sh
		cd ${START_DIR} && unset START_DIR
	fi
else
	START_DIR=${PWD}
	source ${CPKG[PKGSCRIPT]}/${1}.sh
	cd ${START_DIR} && unset START_DIR
fi

# Let us begin
START_DIR=${PWD} && cd ${CPKG[TMP_DIR]}

# Fetch our target, cycling through the mirrors till one works or we die
FLAG=1
while [ ${FLAG} -ne 0 ]; do
	for uri in ${PKG[MIRRORS]}; do
		cfetch ${uri} && FLAG=0 && break
	done
	if [ ${FLAG} -ne 0 ]; then
		log_error "Mirrors exhausted."
		FLAG=0
	fi
done

# Extract our target
cextract ${CPKG[TMP_DIR]}/${PKG[FNAME]}

# Get into our source dir
cd ${PKG[NAME]}

# Configure
cconfigure ${PKG[CONFIGURE]}

# Make install
cinstall ${CPKG[TMP_DIR]}/${PKG[FNAME]}

# Cleanup after ourselves
cd ${CPKG[TMP_DIR]}
rm -rf ${PKG[FNAME]} ${PKG[NAME]}

# And go back to where we started from
cd ${START_DIR}

