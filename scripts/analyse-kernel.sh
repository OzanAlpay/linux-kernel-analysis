#!/bin/bash

help() {
	echo "Usage: $0 [-r] [-s] [-c] [-i]"
	echo "Or you can directly provide a analysisconfig file with [--configfile]"
	echo "  -r,  kernel-repository"
	echo "  -s,  kernel-sha"
	echo "  -c,  kernel-configuration"
	echo "  -i,  inferconfig-file location"
	echo "  --configfile, analysisconfig file for build"
	echo "Example: $0 -r linux-stable -s d8a5b80568a9 -c defconfig -i [absolute-path-to-file]"
	echo "Example with analysisconfig file: $0 --configfile [absolute-path-to-file]"
	echo "Before use it, please be sure you set KERNEL_SRC_BASE variable correctly"
	exit 1
}
assign_default_values() {
	KERNEL_REPOSITORY="$KERNEL_SRC_BASE/stable/linux-stable"
	KERNEL_VERSION="d8a5b80568a9"
	KERNEL_CONFIG="defconfig"
	INFERCONFIG_LOCATION="$SCRIPTS_DIRECTORY/files/inferconfig"
}
set_kernel_repository() {
	if [ ! -z "$1" ]; then
		case $1 in
			torvalds | stable | next )
			if [ "$1" == "torvalds" ]; then
				echo "Torvalds!"
				KERNEL_REPOSITORY="$KERNEL_SRC_BASE/torvalds/linux"
			elif [ "$1" == "stable" ]; then
				echo "Stable!"
				KERNEL_REPOSITORY="$KERNEL_SRC_BASE/stable/linux-stable"
			elif [ "$1" == "next" ]; then
				echo "Next!"
				KERNEL_REPOSITORY="$KERNEL_SRC_BASE/next/linux-next"
			else
				echo "Invalid Kernel Repository Parameter!"
				echo "You can pass -> torvalds | stable | next"
				exit 1;
			fi
		esac
	else
		echo "You provided an empty KERNEL_REPOSITORY parameter!"
		echo "Script will use linux-stable repository for this run!"
		KERNEL_REPOSITORY="$KERNEL_SRC_BASE/stable/linux-stable"
		exit 1;
	fi
}
set_kernel_config() {
	if [ ! -z "$1" ]; then
		case $1 in
			allnoconfig | allmodconfig | allyesconfig | defconfig | randconfig )
			KERNEL_CONFIG="$1"
			;;
	*)
		echo "You provided a KERNEL_CONFIG parameter but it is not a valid kernel configuration!"
		exit 1
	esac
	else
		echo "You provided an empty KERNEL_CONFIG parameter, script will use default value" ##Can it happen in practice??
		KERNEL_CONFIG="defconfig"
	fi
}
set_inferconfig_file_location() {
	if  [ -f "$1" ]; then
		INFERCONFIG_LOCATION="$1"
	else
		echo "Couldn't read inferconfig file, will use default"
		INFERCONFIG_LOCATION= "$SCRIPTS_DIRECTORY/files/inferconfig"
	fi
}
read_and_set_variables_from_analysisconfig() {
	if [ -f "$1" ]; then
		source $1
	else
		echo "Couldn't read analysisconfig file!"
		exit 1;
	fi
}
# Check KERNEL_SRC_BASE
if [ -z "$KERNEL_SRC_BASE" ]; then 
	echo "Please set KERNEL_SRC_BASE first"
	help
	exit 1
elif [ ! -d "$KERNEL_SRC_BASE" ]; then
	echo "KERNEL_SRC_BASE does not point to a directory"
	help
	exit 1
fi
SCRIPTS_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#KERNEL_STABLE_DIRECTORY="$KERNEL_SRC_BASE/stable/linux-stable"
# User need help or called without params
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	help
	exit 0
fi
assign_default_values
while [[ "$#" > 0 ]]; do case $1 in
  -r) set_kernel_repository "$2"; shift; shift;;
  -s) KERNEL_HEAD_SHA="$2"; shift; shift;;
  -c) set_kernel_config "$2"; shift; shift;;
  -i) set_inferconfig_file_location "$2"; shift; shift;;
  --configfile) read_and_set_variables_from_analysisconfig "$2"; shift; shift;;
  *) help; shift; shift; exit 1;;
esac; done
if [ ! -d "$KERNEL_REPOSITORY" ]; then
	echo "Path $KERNEL_REPOSITORY doesn't point to a directory"
	echo "Please fix it and then run script"
	exit 1
fi
echo "KERNEL_REPOSITORY is = $KERNEL_REPOSITORY"
cd $KERNEL_REPOSITORY
#git clean -f -d
#git checkout .
git checkout $KERNEL_HEAD_SHA
cp "$INFERCONFIG_LOCATION" "$KERNEL_REPOSITORY/.inferconfig"
git apply "$SCRIPTS_DIRECTORY/files/0001-Set-default-CC-to-Clang-from-Makefile.patch"
DOCKER_NAME="kernel-analysis"
docker run -v "$KERNEL_REPOSITORY:/linux/" --interactive --tty $DOCKER_NAME \
/bin/sh -c "cd linux && make clean && make $KERNEL_CONFIG && infer capture -- make -j40 && git checkout . && git checkout master && rm .inferconfig"
