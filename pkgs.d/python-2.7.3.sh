# This is disabled until such time as I can verify what is installed already
#cdepend yaml-0.1.4

declare -A PKG
# Package name
PKG[NAME]=Python-2.7.3
# Extension
PKG[EXT]=tar.bz2
# Convenience
PKG[FNAME]="${PKG[NAME]}.${PKG[EXT]}"
# Mirrors
PKG[MIRRORS]="http://pkgs.fedoraproject.org/repo/pkgs/python/${PKG[FNAME]}/c57477edd6d18bd9eeca2f21add73919/${PKG[FNAME]} http://www.python.org/ftp/python/2.7.3/${PKG[FNAME]}"
# Patches (UNSUPPORTED)
PKG[PATCHES]=""
# Configure args
PKG[CONFIGURE]=""

