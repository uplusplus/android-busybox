basepath=$(cd `dirname $0`; pwd)
pushd ..
 ./make_single_applets.sh UDHCPD
 cp busybox_UDHCPD ${basepath}/
 popd