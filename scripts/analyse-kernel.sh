#!/bin/bash

help() {
	echo "Usage: $0 [-r] [-c]"
	echo "Or you can directly provide a analysisconfig file with [--analysisconfig]"
	echo "  -r,  kernel-repository"
	echo "  -c,  kernel-configuration" # Add extra explanation,after be sure about works well.
	echo "  -cc, compiler" #Maybe a better name?
	echo "  optional -i,  inferconfig-file location"
	echo "  optional --analysisconfig, analysisconfig file for build"
	echo "  optional --no-analyze, don't run infer analyze after infer capture finishes"
	echo "Example: $0 -r stable -c defconfig -i [absolute-path-to-file]"
	echo "Example with analysisconfig file: $0 --configfile files/analysisconfig"
	echo "$0 --configfile [full-path-to-file] example: ./analyse-kernel --analysisconfig /home/x/y/z/analysisconfig"
	echo "Before use it, please be sure you set KERNEL_SRC_BASE variable correctly"
	exit 1
}
set_kernel_repository() {
	if [ ! -z "$1" ]; then
		case $1 in
			torvalds | stable | next )
			if [ "$1" == "torvalds" ]; then
				KERNEL_REPOSITORY="$KERNEL_SRC_BASE/torvalds/linux"
			elif [ "$1" == "stable" ]; then
				KERNEL_REPOSITORY="$KERNEL_SRC_BASE/stable/linux-stable"
			elif [ "$1" == "next" ]; then
				KERNEL_REPOSITORY="$KERNEL_SRC_BASE/next/linux-next"
			else #Look for file repository
				echo "Invalid Kernel Repository Parameter!"
				echo "You can pass -> torvalds | stable | next"
				exit 1;
			fi
		esac
	else
		echo "You provided an empty KERNEL_REPOSITORY parameter!"
		echo "Acceptable parameters are =  torvalds | stable | next"
		exit 1;
	fi
}
set_compiler() { #TODO after checking it works well, add some extra warnings for user
	SELECTEDCC="$1"
}
set_kernel_config() { #Test all options one by one, then start to fix TODOS
	case $1 in
		allnoconfig | allmodconfig | allyesconfig | defconfig | randconfig )
		KERNEL_CONFIG="$1"
		;;
	*)	
		if [ -f "$1" ]; then #Copy Kernel File from given location
			cp "$1" "$KERNEL_REPOSITORY/.config"
		elif [ -f "$KERNEL_REPOSITORY/.config" ]; then #Use .config file, that already exists in repository
			echo "Script will use .config file, that already exists in $KERNEL_REPOSITORY"
		else
			echo "You didn't provide any kernel-configuration, and there isn't any .config file in repository"
			echo "Valid Parameters are = allnoconfig | allmodconfig | allyesconfig | defconfig | randconfig"
			echo "OR you can give a config file directly"
			exit 1;
		fi
	esac
}
set_inferconfig_file_location() {
	if [ -f "$SCRIPTS_DIRECTORY/$1" ]; then
		INFERCONFIG_LOCATION="$SCRIPTS_DIRECTORY/$1"
	elif [ -f "$1" ]; then
		INFERCONFIG_LOCATION="$1"
	fi
}
set_scripts_directory() {
	SCRIPTS_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
}
set_analyze() {
	DONT_RUN_ANALYZE=1
}
finalize_command() {
	if [ "$DONT_RUN_ANALYZE" == "1" ]; then
		RUN_COMMAND=${RUN_COMMAND/" && infer analyze"}
	fi
	if [ -z "$KERNEL_CONFIG" ]; then ## Means user didn't provided any kernel-configuration parameter
		echo "You didnt provided a Kernel Configuration Parameter!"
		echo "Script will use .config file, that inside $KERNEL_REPOSITORY"
		RUN_COMMAND=${RUN_COMMAND/"make  &&"}
	fi
	echo "RUN COMMAND is = $RUN_COMMAND"
}
read_and_set_variables_from_analysisconfig() {
	if [ -f "$1" ]; then
		source $1
	else
		echo "Couldn't read analysisconfig file!"
		exit 1;
	fi
}
check_kernel_src_base_valid() {
	if [ -z "$KERNEL_SRC_BASE" ]; then 
		echo "Please set KERNEL_SRC_BASE first"
		help
		exit 1
	elif [ ! -d "$KERNEL_SRC_BASE" ]; then
		echo "KERNEL_SRC_BASE does not point to a directory"
		help
		exit 1
	fi
}
check_kernel_repository_valid() {
	if [ -z "$KERNEL_REPOSITORY" ]; then
		echo "You must provide a target kernel repository"
		echo "Valid parameters are =  torvalds | stable | next"
		exit 1;
	elif [ ! -d "$KERNEL_REPOSITORY" ]; then # Check KERNEL_REPOSITORY is a directory or not
		set_kernel_repository "$KERNEL_REPOSITORY"
	fi
}
#check_kernel_configuration_valid() {
#	if [ -z "$KERNEL_CONFIG" ]; then # Check KERNEL_CONFIG variable is set
#		echo "You must provide a valid kernel configuration"
#		echo "Valid Parameters are = allnoconfig | allmodconfig | allyesconfig | defconfig | randconfig"
#		exit 1;
#	fi
#}
check_inferconfig_exists() {
	if [ -f "$INFERCONFIG_LOCATION" ]; then # Highest priority is parameter
		cp "$INFERCONFIG_LOCATION" "$KERNEL_REPOSITORY/.inferconfig"
	elif [ -f "$SCRIPTS_DIRECTORY/$INFERCONFIG_LOCATION" ]; then #Second priority is analysisconfig file
		cp "$SCRIPTS_DIRECTORY/$INFERCONFIG_LOCATION" "$KERNEL_REPOSITORY/.inferconfig"
	elif [ -f "$KERNEL_REPOSITORY/.inferconfig" ]; then #If still we couldn't a valid inferconfig file, but there is a .inferconfig in source-repository use it instead of raising an error
		echo "Script will use .inferconfig file, that already exists in $KERNEL_REPOSITORY"
	else
		echo "You should provide a .inferconfig file in the root of linux-source repository"
		echo "Or you must provide a valid inferconfig file path"
		exit 1;
	fi
		
}
can_checkout_successfully() {
	CHECKOUT_RESULT=$(git checkout "$KERNEL_HEAD_SHA" 2>&1 | grep "error")
	if [ -n "$CHECKOUT_RESULT" ]; then #Dont force to anything just raise an error to avoid any previous work-loss
		echo "Failed to checkout to $KERNEL_HEAD_SHA successfull successfully"
		echo "Please check your linux source directory!"
		exit 1;
	fi	
}	
does_user_need_help() {
	if [[ "$1" == "-h" || "$1" == "--help" ]]; then
		help
		exit 0
	fi
}
## MAIN ##
# Check KERNEL_SRC_BASE
check_kernel_src_base_valid
set_scripts_directory
does_user_need_help "$1"
# Get Parameters, validate them, assign them variables.
while [[ "$#" > 0 ]]; do case $1 in
  -r) set_kernel_repository "$2"; shift; shift;;
  -c) set_kernel_config "$2"; shift; shift;;
  -cc) set_compiler "$2"; shift; shift;;
  -i) set_inferconfig_file_location "$2"; shift; shift;;
  --analysisconfig) read_and_set_variables_from_analysisconfig "$2"; shift; shift;;
  --no-analyze) set_analyze "$2"; shift; shift;;
  *) help; shift; shift; exit 1;;
esac; done
RUN_COMMAND="cd linux && make clean && make $KERNEL_CONFIG && infer capture -- make CC=$SELECTEDCC HOSTCC=$SELECTEDCC -j40 && infer analyze"
# Check KERNEL_REPOSITORY variable is set
check_kernel_repository_valid
# check_kernel_configuration_valid
check_inferconfig_exists
finalize_command
cd $KERNEL_REPOSITORY
if [ ! -z "$KERNEL_HEAD_SHA" ]; then
	can_checkout_successfully
fi
DOCKER_NAME="kernel-analysis"
docker run -v "$KERNEL_REPOSITORY:/linux/" --interactive --tty $DOCKER_NAME \
/bin/sh -c "$RUN_COMMAND"
