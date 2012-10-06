
cpkg() {
  case "${1}" in
    help)
      echo
      echo "cpkg <command> <...>"
      echo
      echo "Commands:"
      echo "  list [pkg]                             List packages or versions of [pkg]"
      echo "  use [global|(session)] <pkg>-<ver>     Use <pkg>-<ver>"
      echo "  drop [global|(session)] <pkg>-<ver>    Stop using <pkg>-<ver>"
      echo "  log                                    Shows the logfile for your session."
      echo "  recycle                                Regenerate the session paths."
      echo "  renv                                   Rebuild environment variables."
      echo
      echo "In progress:"
      echo "  search <pkg>                           Search build files and packages"
      echo "  install [binary|(build)] <pkg>         Install <pkg>"
      echo "  remove <pkg>                           Remove <pkg>"
      echo
      ;;
    list)
      echo "Listing packages:"
      for itm in $(ls ${CPKG[PKG_DIR]}/|grep "${CPKG[OS_STAMP]}${2}"); do
     		echo "[$(cpkg_belongs_to ${itm})] $(echo ${itm}|awk -F`uname -m`-- '{print $2}')"
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
         	cpkg ${1} session ${2}
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
      $(which rm) -rf ${CPKG[SESSION]}
      mkdir -p ${CPKG[SESSION]}
      cp ${tmp} ${CPKG[SESSION]}/.packages
      cat ${CPKG[GLOBAL]}/.packages ${CPKG[SESSION]}/.packages > ${tmp}
      for itm in $(cat ${tmp}); do
        slndir ${CPKG[PKG_DIR]}/${itm}/ ${CPKG[SESSION]}/
      done
      rm -f ${tmp} ; unset tmp
      cpkg renv
      ;;
    renv)
      log_info "Rebuilding user environment: "
      for itm in $(ls ${CPKG[ENV_DIR]}/); do
        . ${CPKG[ENV_DIR]}/${itm}
      done
      ;;
    *)
      cpkg help 
      ;;
  esac
}
