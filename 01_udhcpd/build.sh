# !/bin/bash

basepath=$(cd `dirname $0`; pwd)
pushd $(dirname $0)/../

if [ $# -ne 2 ];then
    echo "USAGE: $0 -a arm/arm64"
    exit 1
fi

while getopts :a:h: name
do
    case $name in
    a)
        arch=$OPTARG
    ;;
    *)
        echo  "USAGE: $0 -a arm/arm64"
        exit 1
    ;;
    esac
done

case $arch in
	arm)
	prefix=arm-linux-androideabi
	;;
	arm64)
	prefix=aarch64-linux-android
	;;
esac

echo CROSS_COMPILER_PREFIX:$prefix

sed -i "s/CONFIG_CROSS_COMPILER_PREFIX=.*/CONFIG_CROSS_COMPILER_PREFIX=\"${prefix}-\"/g" .config

command -v $prefix-gcc

if ! command -v $prefix-gcc; then
	export PATH=$PATH:~/$prefix/bin
	echo PATH=$PATH
fi

 ./make_single_applets.sh UDHCPD
 cp busybox_UDHCPD ${basepath}/udhcpd_$arch
 popd