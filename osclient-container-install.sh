#!/usr/bin/env bash

# Copyright (c) 2018 Catalyst.net Ltd
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Apache License Version 2.0, January 2004.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Apache License Version 2.0
#
# You should have received a copy of the Apache License Version 2.0
# along with this program.  If not, see http://www.apache.org/licenses/
#

#------------------------------------------------------------------------------
# Parameters
#-----------------------------------------------------------------------------
INSTALL_DIR=""
CONFIG_FILE="$HOME/.config/openstackclient-container/cloud-container.cfg"
OPENSTACK_LAUNCHER="osclient-container"
ALIAS_NAME="osc"
NEWPATH=
DOCKERLINK="https://docs.docker.com/install/"

DEBUG=
# colour data for message prompt
GREEN="\e[92m" # for success output
YELLOW="\e[93m" # for debug output
RED="\e[91m" # for error output
NC='\033[0m' # remove colour from output

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
usage() {
  cat <<USAGE_DOC
  Usage: $(basename $0)
  This is a wrapper script to install the openstackclient container
USAGE_DOC
  exit 0
}

check_docker_exists(){
  docker -v &> /dev/null
  if [ $? -ne 0 ]; then
    MSG="docker is not installed!"
    echo -e  "${RED}${MSG}${NC} \n" 2>&1
    echo "
      Please check out the following link to install docker: ${DOCKERLINK}

      once installed re-run ${INSTALL_DIR}/${OPENSTACK_LAUNCHER}
    "
    exit 1
  fi
}

getConfig() {
  if [ -e $CONFIG_FILE ];  then
    INSTALL_DIR=$(grep install-dir $CONFIG_FILE|awk -F ":" '{ print $2 }'| sed -e 's/^[[:space:]]//')
  else
    # no config file found re-run fetch-installer.sh
    echo "The config file $CONFIG_FILE could not be found, please re-run the installer"
  fi

}
create_os_launcher(){
  if [ ! -d ${INSTALL_DIR} ]; then
    mkdir ${INSTALL_DIR}
  else
    if [ ${DEBUG} ]; then
      MSG="${INSTALL_DIR} already exists, skipping..."
      echo -e  "${YELLOW}${MSG}${NC}"
    fi
  fi

cat << 'EOF' > ${INSTALL_DIR}/${OPENSTACK_LAUNCHER}
#!/usr/bin/env bash

#------------------------------------------------------------------------------
# Parameters
#------------------------------------------------------------------------------

OPENRCFILE="False"
LOCALENV="False"
MODE="interactive"
FILEPATH='.openrc'
FILEREGEX='*-openrc.sh'

EXTRAARGS=''
DOCKER_TAG=
DOCKERIMAGE="catalystcloud/openstackclient-container"

OS_IDENTITY_API_VERSION="3"
OS_AUTH_URL="https://api.cloud.catalyst.net.nz:5000/"

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------

# If ALIAS is run with -s as the only parameter will drop the user into a
# bash shell

parse_args(){
  while getopts su: OPTION; do
    case "$OPTION" in
      s)
        MODE="shell"
        ;;
      v)
        # get the required docker container version if passed
        DOCKER_TAG="$OPTARG"
        ;;
      ?)
        cat <<USAGE_DOC
Usage: $(basename $0) [-s] [-v <version>]
   -s   drops into bash shell rather than interactive openstackclient tool
   -v   the container tag version to update to
USAGE_DOC
        exit 1 ;;
    esac
  done

  if [ "${MODE}" == "shell" ]; then
    EXTRAARGS='--entrypoint=/bin/bash'
  fi
}

handle_interruptions() {
  exit 130
}

# Look for $OS_* environment variables. If not defined, look for openrc files
# under /${HOME}/${FILEPATH}. The precendence is set by this function.

get_credentials() {
  # for the osc container, you need at minimum: OS_AUTH_URL, OS_USERNAME/OS_USER_ID,
  # OS_IDENTITY_API_VERSION, and OS_PASSWORD if not asking for it interactively.
  if [ ${OS_USERNAME} ] && [[ ${OS_PASSWORD} || ${OS_USER_ID} ]]; then
    LOCALENV="True"
  # Search for OpenStack openrc files
  elif find "${HOME}/${FILEPATH}" -name "${FILEREGEX}"; then
    OPENRCFILE="True"
  fi
}

run_container(){

  # check if cloud tools docker image exists, if not pull latest. If a tag is
  # provided for a specific image version then pull that version
  IMAGEID=$(docker images --filter "reference=${DOCKERIMAGE}" --format "{{.ID}}")
  if [ ! ${IMAGEID} ]; then
    docker pull ${DOCKERIMAGE}:latest
  elif [ ${DOCKER_TAG} ]; then
    docker pull ${DOCKERIMAGE}:${DOCKER_TAG}
  fi

  if [ $? -ne 0 ]; then
    echo "Unable to retrieve ${DOCKERIMAGE}"
    exit 1
  fi

  if [ "${OPENRCFILE}" == "True" ]; then
    docker run -it --rm \
    --volume ${HOME}:/home/ubuntu \
    --env "OPENRCFILE=True" \
    --hostname osclient-container ${EXTRAARGS} ${DOCKERIMAGE} ${*}
  elif [ "${LOCALENV}" == "True" ]; then
    docker run -it --rm \
    --volume ${HOME}:/home/ubuntu/ \
    --env "OS_PASSWORD=${OS_PASSWORD}" \
    --env "OS_USERNAME=${OS_USERNAME}" \
    --env "OS_AUTH_URL=${OS_AUTH_URL}" \
    --env "OS_REGION_NAME=${OS_REGION_NAME}" \
    --env "OS_PROJECT=${OS_PROJECT_NAME}" \
    --env "OS_IDENTITY_API_VERSION=${OS_IDENTITY_API_VERSION}" \
    --env "LOCALENV=True" \
    --hostname osclient-container ${EXTRAARGS} ${DOCKERIMAGE} ${*}
  else
    docker run -it --rm \
    --volume ${HOME}:/home/ubuntu/ \
    --hostname osclient-container ${EXTRAARGS} ${DOCKERIMAGE} ${*}
  fi
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

# Handle ctrl-c (SIGINT)
trap handle_interruptions INT

parse_args "$@"
get_credentials
run_container ${*}

EOF

chmod u+x ${INSTALL_DIR}/${OPENSTACK_LAUNCHER}
}


create_alias(){
  ALIAS="alias ${ALIAS_NAME}='${INSTALL_DIR}/${OPENSTACK_LAUNCHER}'"

  if [ -e ${HOME}/.bash_aliases ]; then
    if [ ${DEBUG} ]; then
      MSG="updating .bash_aliases entry"
      echo -e  "${YELLOW}${MSG}${NC}"
    fi
    sed -i '/${ALIAS}/d' ${HOME}/.bash_aliases
    # make sure to append so as to not clobber existing alias entries
    echo "${ALIAS}" >> "${HOME}"/.bash_aliases
  else
    if [ ${DEBUG} ]; then
      MSG="creating .bash_aliases entry"
      echo -e  "${YELLOW}${MSG}${NC}"
    fi
    echo ${ALIAS} > ${HOME}/.bash_aliases
  fi
}


update_path(){
  # if ${INSTALL_DIR} not in ${PATH} update path in .bashrc
  if [[ ! ${PATH} =~ ${INSTALL_DIR} ]]; then
    if [ ${DEBUG} ]; then
      MSG="adding ${INSTALL_DIR} to \$PATH"
      echo -e  "${YELLOW}${MSG}${NC}"
    fi
    NEWPATH=${INSTALL_DIR}:${PATH}
  fi

  if [ ${NEWPATH} ]; then
    MSG="
    Please run 'source ~/.bashrc' to enable changes to \$PATH
    The alias '${ALIAS}' was added to your .bash_aliases file.
    "
    echo -e  "${GREEN}${MSG}${NC}"
  fi

  if [ ! ${NEWPATH} ]; then
    MSG="
    The alias '${ALIAS}' was added to your .bash_aliases file.
    Please run 'source ${HOME}/.bash_aliases' to make this available.
    "

    echo -e  "${GREEN}${MSG}${NC}"
  fi
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

check_docker_exists
getConfig
create_os_launcher
create_alias
update_path
