START_DIR=${PWD}
# This is disabled until such time as I can verify what is installed already
#cdepend yaml-0.1.4

declare -A PKG
# Package name
PKG[NAME]=ruby-1.9.3-p374
# Extension
PKG[EXT]=tar.gz
# Convenience
PKG[FNAME]="${PKG[NAME]}.${PKG[EXT]}"
# Mirrors
PKG[MIRRORS]="http://pkgs.fedoraproject.org/repo/pkgs/ruby/${PKG[FNAME]}/90b6c327abcdf30a954c2d6ae44da2a9/${PKG[FNAME]} http://ftp.ruby-lang.org/pub/ruby/1.9/${PKG[FNAME]}"
# Patches (UNSUPPORTED)
PKG[PATCHES]=""
# Configure args
PKG[CONFIGURE]="--disable-install-doc --enable-shared"

