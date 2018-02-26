# The OpenStackClient container installer script

## Overview
To provide the OpenstackClient command line tools pre-installed, with all of it's dependencies, in a docker container.

### The Installer Script
The purpose of this script (__fetch-installer.sh__) is to simplify the process of obtaining and configuring the OpenStackClient container. The command shown below is going to download a copy of the installer script to the user's machine and run it. That script, in turn, creates a launcher script and places a copy in the directory specified by the user, creating this directory in the process if it does not already exist.

Finally it adds an alias in the user's .bash_aliases file to allow them to run commands and pass them directly to the [OpenStackClient](https://docs.openstack.org/python-openstackclient/latest/) command line tool.

#### Using The Alias
Here is an example of the _default_ alias created by the installer script in the .bash_aliases file:

```bash
alias osc='<install_dir>/osclient-container'
```
A typical openstackclient commands looks something like this:

```bash
openstack server list
```

The alias created by the script takes the place of openstack keyword in the command shown above. So in order to run a command through the openstackclient within the container the format would be like this:

```bash
osc server list
```

This is done in order to differentiate calls to the container versus calls to a locally installed version of the openstack client, should one exist.

### The Launcher Script
This script (__osclient-container-install.sh__) provides a means to launch a pre-configured docker container that will provide the user with a working instance of the OpenStackClient. The script perfoms the following actions:

- asking for an installation directory, the default is $HOME
- checks for a valid docker installation, see [install docker](https://docs.docker.com/install/) or take a look at the __install_docker.sh__ script in this repository for an outline of the steps required to achieve this on an ubuntu workstation.
- retrieving the latest version of the OpenStackClient container, see [here](container-README.md) for more information . If a copy exists locally it will be used first, if it is the latest stable version.
- ensuring that valid OpenStack cloud credentials are available, in the following order of precedence:
  - check the current shell for existing OpenStack authentication environment variables
  - check for the existence of a valid openrc file using the naming style '*-openrc.sh', located in the directory ${HOME}/.openrc.
  - prompt the user to supply valid OpenStack cloud username and password
- once the user is authenticated via supplied credentials it will provide a list of valid cloud projects and cloud regions for the user to select from.

#### Launcher configuration

The installer script currently makes use of a couple of hard coded values that users may want to
change. The first is the alias name, which by default this is set as follows:

```
ALIAS_NAME="osc"
```
This can either be modified by editing .bash_aliases directly or by running the following command,
making sure to replace _myalias_ with the alias of your choice.

```
sed -i'.bak' 's/osc/my-alias/' ${HOME}/.bash_aliases
```

Once this variable has been modified ensure that you reload the aliases file so that the new alias
is available in your current terminal session. To do this run the following:

```
source ${HOME}/.bash_aliases
```

The second variable to be aware of is the AUTH_URL value that will connect you to your OpenStack
cloud provider. By default this is configured to use the Catalyst Cloud authentication service.

```
OS_AUTH_URL="https://api.cloud.catalyst.net.nz:5000/"
```

As above you can either edit this value directly in in the launcher script, which by default will
be  

```
${HOME}/openstackclient-tools/osclient-container
```

or simply run the following command, replacing your.auth-url.com:5000 with the appropriate setting
for your cloud provider.

sed -i'.bak' 's/api.cloud.catalyst.net.nz:5000/your.auth-url.com:5000/' osclient-container-install.sh

```
Note:
At the current time this tool only supports v3 of the keystone identity service.

```

#### Credential management

If you do not wish to be prompted for your cloud credentials every time you run an openstack
command via the alias it would pay to do one of the following. The preferred method allows you to
your password just once as it will store it locally inn an environment variable, the alternative
option will still require a password on each run.

The preferred method
- source your *-openrc.sh file in the current terminal session prior to running any openstackclient-container commands

The alternative
- create a directory called ${HOME}/.openrcplace a copy of your *-openrc.sh file in there. The container will detect this and prompt you for your cloud account's password.


## Just Give Me The Tools!
If all you really care about is getting your hands on a working version of the container then simply run the following command from a Linux shell to have a copy installed locally.

```bash
  bash -c "$(wget -qO - https://raw.githubusercontent.com/catalyst-cloud/openstackclient-container/master/fetch-installer.sh)"
```
