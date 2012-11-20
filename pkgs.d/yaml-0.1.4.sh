# Fetch libyaml from yaml.org, and extract it to ${CPKG[TMP_DIR]}
cd ${CPKG[TMP_DIR]}
cfetch 'http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz'

# Extract our tarball
cextract ${CPKG[TMP_DIR]}/yaml-0.1.4.tar.gz

# Get in there and configure it
cd ${CPKG[TMP_DIR]}/yaml-0.1.4
cconfigure # I have no need of arguments for this package

# and install it
cinstall

# and cleanup ourselves
CPKG_PKG_CLEANUP="${CPKG[TMP_DIR]}/yaml-0.1.4 ${CPKG[TMP_DIR]}/yaml-0.1.4.tar.gz"
