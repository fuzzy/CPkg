D_TMP=`which dialog`
D_ARGS="--backtitle CPkg --clear"
D="${D_TMP} ${D_ARGS}"

# Do some housekeeping
unset D_TMP && unset D_ARGS

${D} --radiolist "Select the desired version(s) of Python" 15 50 10 \
	3.3.0 "" off \
	3.2.3 "" off \
	3.1.5 "" off \
	3.0.1 "" off \
	2.7.3 "" on \
	2.6.8 "" off \
	2.5.6 "" off \
	2.4.6 "" off \
	2.3.7 "" off \
	2.2.3 "" off 2>/tmp/dlg.out

declare -A PKG
case "$(cat /tmp/dlg.out)" in
	3.3.0) VERS=3.3.0 ;;
	3.2.3) VERS=3.2.3 ;;
	3.1.5) VERS=3.1.5 ;;
	3.0.1) VERS=3.0.1 ;;
	2.7.3) VERS=2.7.3 ;;
	2.6.8) VERS=2.6.8 ;;
	2.5.6) VERS=2.5.6 ;;
	2.4.6) VERS=2.4.6 ;;
	2.3.7) VERS=2.3.7 ;;
	2.2.3) VERS=2.2.3 ;;
	*) echo $(cat /tmp/dlg.out) ;;
esac


# Package name
PKG[NAME]=Python-${VERS:-2.7.3}
# Extension
PKG[EXT]=tar.bz2
# Convenience
PKG[FNAME]="${PKG[NAME]}.${PKG[EXT]}"
# Mirrors
PKG[MIRRORS]="http://www.python.org/ftp/python/${VERS:-2.7.3}/${PKG[FNAME]}"
# Patches (UNSUPPORTED)
PKG[PATCHES]=""
# Configure args
PKG[CONFIGURE]=""

rm -f /tmp/dlg.out
