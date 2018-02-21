#!/usr/bin/env bash

DISABLE_PROMPTS=""
INSTALL_DIR=""
TOOLS_DIR="openstackclient-tools"
CONFIG_DIR="$HOME/.config/openstackclient-container/"
CONFIG_FILE="cloud-container.cfg"
SCRIPTNAME="osclient-container-install.sh"
SCRIPT_URL="https://raw.githubusercontent.com/chelios/openstackclient-container/master/osclient-container-install.sh"

usage() {
  COMMAND=${0##*/}

  echo "
$COMMAND [ --disable-prompts ] [ --install-dir DIRECTORY ]

Installs the OpenStackClient container launcher by downloading the setup script
($SCRIPTNAME) into a directory of your choosing, and then runs this script to
create an alias to allow easy launching of the tools container.

--disable-prompts
  Disables prompts. Prompts are always disabled when there is no controlling
  tty. Alternatively export CLOUDSDK_CORE_DISABLE_PROMPTS=1 before running
  the script.

--install-dir=DIRECTORY
  Sets the installation root directory to DIRECTORY. The launcher script will be
  installed in DIRECTORY/$TOOLS_DIR. The default location is \$HOME.
" >&2

  exit 2
}

parseArgs() {
  # options may be followed by one colon to indicate they have a required argument
  if ! options=$(getopt -o di: -l disable-prompt,install-dir: -- "$@")
  then
    # something went wrong, getopt will put out an error message for us
    usage
    exit 1
  fi

  set -- $options

  while [ $# -gt 0 ]; do
    case $1 in
      -d|--disable-prompts) DISABLE_PROMPTS=1 ;;
      # for options with required arguments, an additional shift is required
      -i|--install-dir) eval INSTALL_DIR="$2" ; shift;;
      (--) shift; break;;
      (-*) echo "$0: error - unrecognized option $1" 1>&2; usage;;
      (*) break;;
    esac
    shift
  done
}

promptWithDefault() {
  # $1 - the question being asked
  # $2 - the default answer
  # $3 - the variable to assign response to
  set -o noglob
  if [ -z $DISABLE_PROMPTS ]; then
    read -p "$1 [default=$2] " response
    if [ -z $response ]; then
      eval $3="$2"
    else
      eval $3="$response"
    fi
  else
    # INSTALL_DIR not explicitly set by user and prompts dsiabled
    # so use default
    eval $3="$2"
  fi
  set +o noglob
}

promptYN() {
  # $1 - the question being asked
  # $2 - the default answer
  # $3 - the variable to assign response to
  read -p "$1 [default=$2] " response
  if [ -z $response ]; then
    # no response use default
    eval $3="$2"
  else
    eval $3="$response"
  fi
}

checkTTY() {
  if [ ! -t 1 ]; then
    # not a terminal so disable prompts
    DISABLE_PROMPTS=1
  fi
}

fetchScript() {
  # $1 - source URL
  # $2 - local destination filename
  if [ "which wget >/dev/null" ]; then
    wget -O - "$1" > "$2"
  else
    echo " Please ensure wget is installed" >&2
    return 1
  fi
}

writeConfig() {
    # write out config details
    mkdir -p $CONFIG_DIR
    echo "install-dir : $INSTALL_DIR/$TOOLS_DIR" > $CONFIG_DIR/$CONFIG_FILE
}

install() {
  if [ -z $INSTALL_DIR ]; then
    echo "
This will install the launcher scripts in a subdirectory called $TOOLS_DIR
in the installation directory selected below,

"

    promptWithDefault "select the installation directory" "$HOME" INSTALL_DIR
  fi
  DESTDIR=${INSTALL_DIR}/${TOOLS_DIR}
  if [ -e $DESTDIR ]; then
    echo "$DESTDIR already exists!"
    promptmsg="Would you like to remove the old directory?"
    while true; do
      promptYN "$promptmsg" n removedir
      if [ $removedir == 'y' -o $removedir == 'Y' ]; then
        rm -rf "$DESTDIR"
        if [ ! -e "$DESTDIR" ]; then
          break
        fi
        echo "Failed to remove $DESTDIR." >&2
        $promptmsg=""
      fi
    done
  fi
  mkdir -p "$DESTDIR" || return

  # copy script to local
  fetchScript $SCRIPT_URL $DESTDIR/$SCRIPTNAME
  chmod u+x $DESTDIR/$SCRIPTNAME || return

  writeConfig

  # run the launcher setup script
  $DESTDIR/$SCRIPTNAME || return
}

#----------------------------
# Main
#----------------------------
parseArgs "$@"
checkTTY
install
