cdepend yaml-0.1.4

# Fetch libyaml from yaml.org, and extract it to ${CPKG[TMP_DIR]}
cd ${CPKG[TMP_DIR]}
cfetch 'http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p327.tar.gz'

# Extract our tarball
cextract ${CPKG[TMP_DIR]}/ruby-1.9.3-p327.tar.gz

# Get in there and configure it
cd ${CPKG[TMP_DIR]}/ruby-1.9.3-p327
cconfigure --disable-install-doc --enable-shared

# and install it
cinstall

# and cleanup ourselves
CPKG_PKG_CLEANUP="${CPKG[TMP_DIR]}/ruby-1.9.3-p327 ${CPKG[TMP_DIR]}/ruby-1.9.3-p327.tar.gz"
