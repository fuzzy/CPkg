
cpkg() {
  case "${1}" in
    help)
      echo
      echo -e "\033[1;36mUsage\033[4;37m\033[1;37m:\033[0m"
      echo "cpkg <command> <...>"
      echo
      echo -e "\033[1;36mCommands\033[4;37m\033[1;37m:\033[0m"
      echo "  list [pkg]                           List packages or versions of [pkg]"
      echo "  use [global|(session)] <pkg>-<ver>   Use <pkg>-<ver>"
      echo "  drop [global|(session)] <pkg>-<ver>  Stop using <pkg>-<ver>"
      echo "  log                                  Shows the logfile for your session."
      echo "  recycle                              Regenerate the session paths."
      echo "  renv                                 Rebuild environment variables."
	  echo "  freeze [pkg]                         Freeze a package at a given state."
	  echo "  freezer <pkg>                        Show the contents of the freezer, or filtered by <pkg>."
  	  echo "  unfreeze [pkg]                       Unfreeze a package from a given state."
      echo "  remove [pkg]                         Remove <pkg>."
      echo "  search [filter]                      Search through available pkgscripts for [filter]."
      echo "  install [pkg]                        Install package denoted by [pkg]."
      echo
      ;;
    list)
		echo -e "\033[1;36mPackages\033[4;37m\033[1;37m:\033[0m"
    	for itm in $(ls ${CPKG[PKG_DIR]}/|grep "${CPKG[OS_STAMP]}${2}"); do
		echo -e "[$(cpkg_belongs_to ${itm})] $(echo ${itm}|gawk -F'__' '{print $3}')"
        done
 	    ;;
    use)
    	if [ $(cpkg_in_use ${3}) -eq 0 ]; then
        	case "${2}" in
        		global)
            		log_info "Adding ${3} to the global profile."
            		echo "${CPKG[OS_STAMP]}${3}" >> ${CPKG[GLOBAL]}/.packages
            		cpkg recycle
            		;;
          		session) 
            		log_info "Adding ${3} to the session profile."
            		echo "${CPKG[OS_STAMP]}${3}" >> ${CPKG[SESSION]}/.packages
            		cpkg recycle
            		;;
          		*)
            		cpkg ${1} session ${2} 
            		;;
        	esac
      	fi
      	;;
    drop)
    	case "${2}" in
			global)
				if [ $(cpkg_in_use ${3}) -eq 1 ]; then
					log_info "Dropping ${3} from the global profile."
       	 			tempf=$(mktemp /tmp/cpkg.${RND})
	       			grep -v "${CPKG[OS_STAMP]}${3}" ${CPKG[GLOBAL]}/.packages >${tempf}
   		   			mv ${tempf} ${CPKG[GLOBAL]}/.packages
         			cpkg recycle
				fi
	       		;;
       		session) 
				if [ $(cpkg_in_use ${3}) -eq 1 ]; then
					log_info "Dropping ${3} from the session profile."
	       			tempf=$(mktemp /tmp/cpkg.${RND})
   		   			grep -v "${CPKG[OS_STAMP]}${3}" ${CPKG[SESSION]}/.packages >${tempf}
	       			mv ${tempf} ${CPKG[SESSION]}/.packages
         			cpkg recycle
				fi
   				;;
			*)
				for i in ${CPKG[GLOBAL]}/.packages ${CPKG[SESSION]}/.packages; do
					tempf=$(mktemp /tmp/cpkg.${RND})
					grep -v "${CPKG[OS_STAMP]}${3}" ${i} >${tempf}
					mv ${tempf} ${i}
				done
				cpkg recycle
		 		;;
		esac
    	;;    
    log)
      # This needs to show the current sessions logfile
      if [ ! -z "${PAGER}" ]; then
        ${PAGER} ${CPKG[LOGFILE]}
      else
        less ${CPKG[LOGFILE]}
      fi
      ;;
    recycle)
      log_info "Rebuilding session paths: "
      tmp=$(mktemp /tmp/cpkg.${RND})
      cp ${CPKG[SESSION]}/.packages ${tmp}
	  mv ${CPKG[SESSION]} ${CPKG[SESSION]}.old
      mkdir -p ${CPKG[SESSION]}
      cp ${tmp} ${CPKG[SESSION]}/.packages
      cat ${CPKG[GLOBAL]}/.packages ${CPKG[SESSION]}/.packages > ${tmp}
      for itm in $(cat ${tmp}); do
        ${CPKG[LNDIR]} ${CPKG[PKG_DIR]}/${itm}/ ${CPKG[SESSION]}/ $(echo ${itm}|sed -e "s/${CPKG[OS_STAMP]}//g") >/dev/null
      done
      rm -f ${tmp} ; unset tmp
      cpkg renv
	  log_info "Cleaning up"
	  $(which rm) -rf ${CPKG[SESSION]}.old
      ;;
    renv)
      log_info "Rebuilding user environment: "
      for itm in $(ls ${CPKG[ENV_DIR]}/); do
        . ${CPKG[ENV_DIR]}/${itm}
      done
      ;;
	freeze)
		# Check to see that we have a $2
		if [ -z "${2}" ]; then
			log_error "You must provide a package name."
			# Then check to see if our package exists
		elif [ ! -d ${CPKG[PKG_DIR]}/${CPKG[OS_STAMP]}${2} ]; then
			log_error "You must provide a valid package name."
		else 
			# Set a few things straight
			s_dir=${PWD}
			dstamp=$(date +%m%d%y%H%M)
			log_info "Copying ${2}"
			# Run into the pkgdir and sync to temp
			cd ${CPKG[PKG_DIR]}
			tar -cf- ${CPKG[OS_STAMP]}${2} | tar -C ${CPKG[TMP_DIR]}/ -xf-
			# Create the tarball
			log_info "Freezing ${2}"
			cd ${CPKG[TMP_DIR]}
			mv ${CPKG[OS_STAMP]}${2} ${2}--${dstamp}
			tar -czf ${CPKG[FREEZER]}/${2}--${dstamp}.tgz ${2}--${dstamp}/
			# and clean up after ourselves
			log_info "Cleaning up"
			rm -rf ${CPKG[TMP_DIR]}/${2}--${dstamp}
			cd ${s_dir}
		fi
		;;
	freezer)
	    echo -e "\033[1;36mThe freezer\033[4;37m\033[1;37m:\033[0m"
		if [ -z "${2}" ]; then
			for itm in $(ls ${CPKG[FREEZER]}/); do
				pkg=$(echo $(basename ${itm})|awk -F'--' '{print $1}')
				tme=$(echo $(basename ${itm})|awk -F'--' '{print $2}'|awk -F. '{print $1}')
				printf "\t%-20s %8s\n" ${pkg} ${tme}
			done
		else
			if [ ! -z "$(ls ${CPKG[FREEZER]}|grep ${2})" ]; then
				for itm in $(ls ${CPKG[FREEZER]}/*${2}*); do
					pkg=$(echo $(basename ${itm})|awk -F'--' '{print $1}')
					tme=$(echo $(basename ${itm})|awk -F'--' '{print $2}'|awk -F. '{print $1}')
					printf "\t%-20s %13s\n" ${pkg} ${tme}
				done
			fi
		fi
		;;
	unfreeze)
		if [ -z "${2}" ] || [ -z "${3}" ]; then
			log_error "You must supply a package, and a hash."
		else
			if [ ! -f ${CPKG[FREEZER]}/${2}--${3}.tgz ]; then
				log_error "The package and hash you specified are invalid."
			else
				log_info "Extracting iceball"
				tar -C ${CPKG[TMP_DIR]}/ -zxf ${CPKG[FREEZER]}/${2}--${3}.tgz
				mv ${CPKG[TMP_DIR]}/${2}--${3} ${CPKG[PKG_DIR]}/${CPKG[OS_STAMP]}${2}-${3}
			fi
		fi
		;;
	remove)
		if [ -d ${CPKG[PKG_DIR]}/${CPKG[OS_STAMP]}${2} ] && [ ! -z "${2}" ]; then
			log_info "Removing ${2}"
			rm -rf ${CPKG[PKG_DIR]}/${CPKG[OS_STAMP]}${2}
			cpkg recycle
		fi
		;;
	search)
		echo -e "\033[1;36mPkgscripts\033[4;37m\033[1;37m:\033[0m"
		if [ ! -z "${2}" ]; then
			for itm in $(ls ${CPKG[PKGSCRIPT]}/|grep ${2}); do
				echo "  #) ${itm}" | sed -e 's/\.sh//g'
			done
		else
			for itm in $(ls ${CPKG[PKGSCRIPT]}/); do
				echo "  #) ${itm}" | sed -e 's/\.sh//g'
			done				
		fi
		;;
	install)
		if [ ! -z "${2}" ]; then
			if [ ! -f ${CPKG[PKGSCRIPT]}/${2}.sh ]; then
				log_error "You must specify a valid pkgscript."
			else
				${CPKG[CMD_BUILDER]} ${2}
			fi
		else
			log_error "You must specify a pkgscript."
		fi
		;;
    *)
      cpkg help 
      ;;
  esac
}
