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
			tar -C ${CPKG[TMP_DIR]}/ -zxf ${1}
		elif [ ! -z "$(file ${1}|grep xz)" ]; then
			tar -C ${CPKG[TMP_DIR]}/ -zxf ${1}
		elif [ ! -z "$(file ${1}|grep bzip2)" ]; then
			tar -C ${CPKG[TMP_DIR]}/ -jxf ${1}
		fi
	fi
}

# config
cconfigure() {
	log_info "Configuring $(basename ${PWD})"
	./configure --prefix=${CPKG[PKG_DIR]}/${CPKG[OS_STAMP]}$(basename $(pwd)|tr "[:upper:]" "[:lower:]") ${*} >${CPKG[LOG_DIR]}/$(basename ${PWD}).log
}

# install
cinstall() {
	log_info "Building $(basename ${PWD})"
	make >>${CPKG[LOG_DIR]}/$(basename ${PWD}).log
	log_info "Installing $(basename ${PWD})"
	make install >>${CPKG[LOG_DIR]}/$(basename ${PWD}).log
}