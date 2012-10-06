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
  CPKG_SHELL=$(which zsh)
elif [ ! -z "$(echo ${tmp}|grep bash)" ]; then
  CPKG_SHELL=$(which bash)
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
declare -A CPKG

# Be verbose
CPKG[VERBOSE]=1

# Our base directory from wich all others spring
CPKG[BASE_DIR]=${HOME}/.spm

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

# Our pkgbuild files
CPKG[PKGSCRIPT]=${CPKG[BASE_DIR]}/pkgs.d

# Our environment files
CPKG[ENV_DIR]=${CPKG[BASE_DIR]}/env.d

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

# Our verbosity level
# Set this to 1 to see log msgs on the console
CPKG[VERBOSE]=0

# Our toolchain needs setup, so lets do that now
# Lets get our fetching utility
if [ ! -z "$(which fetch)" ]; then
    CPKG[CMD_FETCH]=$(which fetch)
elif [ ! -z "$(which wget)" ]; then
    CPKG[CMD_FETCH]=$(which wget)
elif [ ! -z "$(which curl)" ]; then
    CPKG[CMD_FETCH]=$(which curl)
fi

# Lets make sure we get our hashing utility
if [ ! -z "$(which md5)" ]; then
    CPKG[CMD_HASH]=$(which md5)
elif [ ! -z "$(which md5sum)" ]; then
    CPKG[CMD_HASH]=$(which md5sum)
elif [ ! -z "$(which b64encode)" ]; then
    CPKG[CMD_HASH]=$(which b64encode)
elif [ ! -z "$(which uuencode)" ]; then
    CPKG[CMD_HASH]=$(which uuencode)
fi

# and our compilers
if [ ! -z "$(which gcc)" ]; then
    CPKG[CMD_CC]=$(which gcc)
elif [ ! -z "$(which cc)" ]; then
    CPKG[CMD_CC]=$(which cc)
elif [ ! -z "$(which clang)" ]; then
    CPKG[CMD_CC]=$(which clang)
fi

if [ ! -z "$(which g++)" ]; then
    CPKG[CMD_CXX]=$(which g++)
elif [ ! -z "$(which c++)" ]; then
    CPKG[CMD_CXX]=$(which c++)
elif [ ! -z "$(which clang++)" ]; then
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

cpkg recycle
log_info "Initialization complete."