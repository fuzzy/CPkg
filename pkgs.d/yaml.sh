START_DIR=${PWD}
# This is disabled until such time as I can verify what is installed already
#cdepend yaml-0.1.4

declare -A PKG
# Package name
PKG[NAME]=yaml-0.1.4
# Extension
PKG[EXT]=tar.gz
# Convenience
PKG[FNAME]="${PKG[NAME]}.${PKG[EXT]}"
# Mirrors
PKG[MIRRORS]="http://pkgs.fedoraproject.org/repo/pkgs/libyaml/${PKG[FNAME]}/36c852831d02cf90508c29852361d01b/${PKG[FNAME]} http://pyyaml.org/download/libyaml/${PKG[FNAME]}"
# Patches (UNSUPPORTED)
PKG[PATCHES]=""
# Configure args
PKG[CONFIGURE]=""

