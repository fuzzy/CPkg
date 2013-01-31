# Author: Mike 'Fuzzy' Partin
# License: BSD License, any version you like.
# Purpose:
# I got tired of maintaining multiple project installs in my home directory
# in order to maintain multiple packge installs in my home directory. That
# may sound a bit odd, but think about it. If your are a developer, or just
# like geeking out on languages like I do, you may be playing with Python,
# Ruby, D, or Go, or even any combination of those as I do. If so, you may
# be familiar with pyvm/multipy, govm, rvm, and the like. That is what I'm
# talking about. These projects do the *exact* same thing, but for different
# single package targets. CPKG addresses this by managing multiple versions
# of *any* package, and even setup scripts for building and installing of
# several of the above mentioned languages.

RND='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

# Absolute first thing we do is record in an easy to see place what shell
# we're running under. Currently we only support ZSH, BASH is expected shortly.
# This is the most reliable method I can think of for shell detection
CPKG_SH_PID=$$
# NOTE: TODO: research this, it may only be valid with FreeBSD's ps
tmp=`ps aux|grep ${CPKG_SH_PID}|awk '{print $11}'`
if [ ! -z "$(echo ${tmp}|grep zsh)" ]; then
  CPKG_SHELL=$(which zsh 2>/dev/null)
elif [ ! -z "$(echo ${tmp}|grep bash)" ]; then
  CPKG_SHELL=$(which bash 2>/dev/null)
fi

# If it exists, make a copy of the session hash 
if [ ! -z "${CPKG[HASH]}" ]; then
    HASH_TMP=${CPKG[HASH]}
fi

# Cleanup old values if they exist
if [ ! -z "${CPKG}" ]; then
    unset CPKG
fi

# And kick it off
case "$(basename ${SHELL})" in
	zsh) declare -A CPKG ;;
	bash) declare -A CPKG ;;
esac

# Be verbose
export CPKG_VERBOSE=1

# Our base directory from wich all others spring
CPKG[BASE_DIR]=${HOME}/.cpkg

# Configurations
CPKG[CONF_DIR]=${CPKG[BASE_DIR]}/conf.d

# Library functions and such
CPKG[LIB_DIR]=${CPKG[BASE_DIR]}/lib.d

# Each logins session will go here
CPKG[SESSIONS]=${CPKG[BASE_DIR]}/sessions

# And our logdir
CPKG[LOG_DIR]=${CPKG[SESSIONS]}/logs

# The global session will go here
CPKG[GLOBAL]=${CPKG[SESSIONS]}/global

# Our temp dir
CPKG[TMP_DIR]=${CPKG[BASE_DIR]}/tmp

# Our installed packages
CPKG[PKG_DIR]=${CPKG[BASE_DIR]}/packages

# Our freezer
CPKG[FREEZER]=${CPKG[BASE_DIR]}/freezer

# Our pkgbuild files
CPKG[PKGSCRIPT]=${CPKG[BASE_DIR]}/pkgs.d

# Our environment files
CPKG[ENV_DIR]=${CPKG[BASE_DIR]}/env.d

# Our utility source dir
CPKG[UTIL_SRC]=${CPKG[BASE_DIR]}/utils.s

# Our utility bin dir
CPKG[UTIL_BIN]=${CPKG[BASE_DIR]}/utils

# Lets ensure all our directories exist
TMP=$(mktemp /tmp/cpkg.${RND})
case "${CPKG_SHELL}" in
  bash) 
    echo 'KEYS=${!CPKG}' >${TMP}
    ;;   
  zsh)
    echo 'KEYS=${(k)CPKG}' >${TMP}
    ;;
esac

. ${TMP}
rm -f ${TMP} ; unset TMP

for key in ${KEYS}; do
    if [ ! -d ${CPKG[${key}]} ]; then
        mkdir -p ${CPKG[${key}]}
    fi
done

unset KEYS
 
if [ ! -f ${CPKG[GLOBAL]}/.packages ]; then
    touch ${CPKG[GLOBAL]}/.packages
fi

CPKG[SHPID]=${CPKG_SH_PID}
CPKG[SHELL]=${CPKG_SHELL}

# Our toolchain needs setup, so lets do that now
# Lets make sure we get our hashing utility
if [ ! -z "$(which md5 2>/dev/null|grep -v 'no .* .*')" ]; then
    CPKG[CMD_HASH]=$(which md5)
elif [ ! -z "$(which md5sum 2>/dev/null|grep -v 'no .* .*')" ]; then
    CPKG[CMD_HASH]=$(which md5sum)
elif [ ! -z "$(which b64encode 2>/dev/null|grep -v 'no .* .*')" ]; then
    CPKG[CMD_HASH]=$(which b64encode)
elif [ ! -z "$(which uuencode 2>/dev/null|grep -v 'no .* .*')" ]; then
    CPKG[CMD_HASH]=$(which uuencode)
fi

# and our compilers
if [ ! -z "$(which gcc 2>/dev/null)" ]; then
    CPKG[CMD_CC]=$(which gcc)
elif [ ! -z "$(which cc 2>/dev/null)" ]; then
    CPKG[CMD_CC]=$(which cc)
elif [ ! -z "$(which clang 2>/dev/null)" ]; then
    CPKG[CMD_CC]=$(which clang)
fi

if [ ! -z "$(which g++ 2>/dev/null)" ]; then
    CPKG[CMD_CXX]=$(which g++)
elif [ ! -z "$(which c++ 2>/dev/null)" ]; then
    CPKG[CMD_CXX]=$(which c++)
elif [ ! -z "$(which clang++ 2>/dev/null)" ]; then
    CPKG[CMD_CXX]=$(which clang++)
fi

# Lets set our OS stamp
CPKG[OS_STAMP]="$(uname -s)--$(uname -m)--"

# Now lets pull in our config file, and update all defaults
if [ -f ${CPKG[CONF_DIR]}/cpkg.cfg ]; then
  . ${CPKG[CONF_DIR]}/cpkg.cfg
fi

# If we don't have a hash backup, make a new one
if [ -z "${HASH_TMP}" ]; then
    CPKG[HASH]=$(echo "${USER}@${HOME} $(date)"|${CPKG[CMD_HASH]}|awk '{print $1}')
else
    CPKG[HASH]=${HASH_TMP}
    unset HASH_TMP
fi

# And build our session dirs and defaults file
CPKG[SESSION]="${CPKG[SESSIONS]}/${CPKG[HASH]}"
if [ ! -d ${CPKG[SESSION]} ]; then
    mkdir -p ${CPKG[SESSION]}
fi
if [ ! -f ${CPKG[SESSION]}/.packages ]; then
    touch ${CPKG[SESSION]}/.packages
fi

# And finally our session logfile gets setup.
CPKG[LOGFILE]=${CPKG[LOG_DIR]}/${CPKG[HASH]}.log
if [ ! -e ${CPKG[LOGFILE]} ]; then
  touch ${CPKG[LOGFILE]}
fi

# Now that setup is complete, lets source in the actual code
# Our logging routines
. ${CPKG[LIB_DIR]}/logging.sh

# Our main logic
. ${CPKG[LIB_DIR]}/cpkg.sh

# Our core slndir function
. ${CPKG[LIB_DIR]}/lndir.sh

# Our interface routines
. ${CPKG[LIB_DIR]}/ui.sh

# And our utility functions
. ${CPKG[LIB_DIR]}/utils.sh

# Now lets make sure our utilities are there, and if not, compile them.
# lndir
if [ ! -e ${CPKG[UTIL_BIN]}/lndir ]; then
	if [ ! -e ${CPKG[UTIL_SRC]}/lndir.c ]; then
		log_error "No lndir.c available, and no lndir. Falling back to the *VERY* slow shell version."
		CPKG[LNDIR]=slndir
	else
		log_info "Compiling lndir.c"
		cmd_compile="${CPKG[CMD_CC]} -o ${CPKG[UTIL_BIN]}/lndir ${CPKG[UTIL_SRC]}/lndir.c 2>${CPKG[LOG_DIR]}/lndir-compile.log"
		(eval ${cmd_compile} && CPKG[LNDIR]=${CPKG[UTIL_BIN]}/lndir) || (log_error "lndir.c failed to compile."; CPKG[LNDIR]=slndir)
	fi
else
	CPKG[LNDIR]=${CPKG[UTIL_BIN]}/lndir
fi

#cfetch
if [ ! -e ${CPKG[UTIL_BIN]}/cfetch ]; then
    if [ ! -e ${CPKG[UTIL_SRC]}/cfetch.c ]; then
        log_error "No cfetch.c available. Falling back to using system detected download utility."
    else
        log_info "Compiling cfetch.c"
        cmd_compile="${CPKG[CMD_CC]} -o ${CPKG[UTIL_BIN]}/cfetch -lcurl ${CPKG[UTIL_SRC]}/cfetch.c 2>${CPKG[LOG_DIR]}/cfetch-compile.log"
        (eval ${cmd_compile} && CPKG[CMD_FETCH]=${CPKG[UTIL_BIN]}/cfetch) || (log_error "cfetch.c failed to compile."; CPKG[CMD_FETCH]="NONE")
        if [ "${CPKG[CMD_FETCH]}" = "NONE" ]; then
            if [ ! -z "$(which wget 2>/dev/null)" ]; then
                CPKG[CMD_FETCH]="wget -q"
            elif [ ! -z "$(which fetch 2>/dev/null)" ]; then
                CPKG[CMD_FETCH]="fetch"
            elif [ ! -z "$(which curl 2>/dev/null)" ]; then
                CPKG[CMD_FETCH]="curl"
            fi
        fi
    fi
else
    CPKG[CMD_FETCH]=${CPKG[UTIL_BIN]}/cfetch
fi

# builder
CPKG[CMD_BUILDER]=${CPKG[UTIL_BIN]}/builder.sh

# Ensure this is globally available
export CPKG
