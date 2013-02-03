D_TMP=`which dialog`
D_ARGS="--backtitle CPkg --clear"
D="${D_TMP} ${D_ARGS}"

# Do some housekeeping
unset D_TMP && unset D_ARGS

${D} --radiolist "Select the desired version(s) of Ruby" 15 50 10 \
	"1.8.6-p420" "" off \
	"1.8.7-p358" "" off \
	"1.9.1-p431" "" off \
	"1.9.2-p320" "" off \
	"1.9.3-p374" "" on \
	"1.9-stable" "" off \
	"2.0.0-rc1" "" off 2>/tmp/dlg.out
CHOICE_STATUS=$?
CHOICE_DATA=$(cat /tmp/dlg.out)
rm -f /tmp/dlg.out

if [ ${CHOICE_STATUS} -eq 0 ]; then
	declare -A PKG
	case "${CHOICE_DATA}" in
		1.8.6-p420) VERS=1.8.6-p420 ;;
		1.8.7-p358) VERS=1.8.7-p358 ;;
		1.9.1-p431) VERS=1.9.1-p431 ;;
		1.9.2-p320) VERS=1.9.2-p320 ;;
		1.9.3-p374) VERS=1.9.3-p374 ;;
		1.9-stable) VERS=1.9-stable ;;
		2.0.0-rc1) VERS=2.0.0-rc1 ;;
		*) echo $(cat /tmp/dlg.out) ;;
	esac

	# Package name
	PKG[NAME]=ruby-${VERS:-1.9.3-p374}
	# Extension
	PKG[EXT]=tar.bz2
	# Convenience
	PKG[FNAME]="${PKG[NAME]}.${PKG[EXT]}"
	# Mirrors
	PKG[MIRRORS]="http://www.mirrorservice.org/pub/ruby/${PKG[FNAME]} http://ftp.cs.pu.edu.tw/Unix/lang/Ruby/${PKG[FNAME]} http://ruby.taobao.org/mirrors/ruby/${PKG[FNAME]} ftp://ftp.ruby-lang.org/pub/ruby/${PKG[FNAME]}"
	# Patches (UNSUPPORTED)
	PKG[PATCHES]=""
	# Configure args
	PKG[CONFIGURE]=""
else
	exit
fi	
