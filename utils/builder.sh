#!/usr/bin/env bash

source ~/.cpkg/cpkg.sh

# fetch
cfetch() {
	${CPKG[CMD_FETCH]} $*
}

# extract
cextract() {
	if [ ! -f ${1} ]; then
		log_error "You must supply a valid filename."
	else
		log_info "Extracting $(basename ${1})"
		if [ ! -z "$(file ${1}|grep gzip)" ]; then
			tar -zxf ${1} -C ${CPKG[TMP_DIR]}/
		elif [ ! -z "$(file ${1}|grep xz)" ]; then
			tar -zxf ${1} -C ${CPKG[TMP_DIR]}/
		elif [ ! -z "$(file ${1}|grep bzip2)" ]; then
			tar -jxf ${1} -C ${CPKG[TMP_DIR]}/
		fi
	fi
}

# config
cconfigure() {
	log_info "Configuring $(basename ${PWD})"
	./configure --prefix=${CPKG[PKG_DIR]}/${CPKG[OS_STAMP]}$(basename $(pwd)|tr "[:upper:]" "[:lower:]") ${*} 2>${CPKG[LOG_DIR]}/$(basename ${PWD})-error.log 1>${CPKG[LOG_DIR]}/$(basename ${PWD}).log
}

# install
cinstall() {
	log_info "Building $(basename ${PWD})"
	make 2>${CPKG[LOG_DIR]}/$(basename ${PWD})-error.log 1>${CPKG[LOG_DIR]}/$(basename ${PWD}).log
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
		source ${CPKG[PKGSCRIPT]}/${1}.sh
	fi
else
	source ${CPKG[PKGSCRIPT]}/${1}.sh
fi

if [ ! -z "${CPKG_PKG_CLEANUP}" ]; then
	log_info "Cleaning up."
	for i in ${CPKG_PKG_CLEANUP}; do
		rm -rf ${i}
	done
fi
