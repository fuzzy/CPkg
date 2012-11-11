if [ "$(whoami)" = "root" ]; then
  export PATH=${CPKG[SESSION]}/bin:${CPKG[SESSION]}/sbin:${SPATH}:/bin:/sbin:/usr/local/sbin:/usr/local/bin:/usr/pkg/bin:/usr/pkg/sbin:/usr/bin:/usr/sbin:/opt/bin:/opt/sbin
else
  export PATH=${CPKG[SESSION]}/bin:/bin:/usr/bin:/usr/local/bin:/usr/pkg/bin:/opt/local/bin:$PATH
fi
export CFLAGS=-I${CPKG[SESSION]}/include
export LDFLAGS="-L${CPKG[SESSION]}/lib -L${CPKG[SESSION]}/lib32  -L${CPKG[SESSION]}/lib64"
export LD_LIBRARY_PATH=${CPKG[SESSION]}/lib:${CPKG[SESSION]}/lib32:${CPKG[SESSION]}/lib64:/lib:/lib32:/lib64:/usr/lib:/usr/lib32:/usr/lib64:/usr/pkg/lib:/usr/pkg/lib32:/usr/pkg/lib64:/usr/local/lib:/usr/local/lib32:/usr/local/lib64:/opt/lib:/opt/lib32:/opt/lib64
export LD_RUN_PATH=${CPKG[SESSION]}/lib:${CPKG[SESSION]}/lib32:${CPKG[SESSION]}/lib64:/lib:/lib32:/lib64:/usr/lib:/usr/lib32:/usr/lib64:/usr/pkg/lib:/usr/pkg/lib32:/usr/pkg/lib64:/usr/local/lib:/usr/local/lib32:/usr/local/lib64:/opt/lib:/opt/lib32:/opt/lib64
export PKG_CONFIG_PATH=${CPKG[SESSION]}/lib/pkgconfig:/lib/pkgconfig:/usr/lib/pkgconfig:/usr/pkg/lib/pkgconfig:/usr/local/lib/pkgconfig:/opt/lib/pkgconfig
