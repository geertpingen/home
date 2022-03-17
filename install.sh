#!/bin/sh


usage() {
    cat <<USAGE

    Usage: $0 [-r remove]

    Options:
        -r, --remove:        Remove all packages
USAGE
    exit 1
}

REMOVE_PACKAGES=false
while [ "$1" != "" ]; do
    case $1 in
    -r | --remove)
        REMOVE_PACKAGES=true
        ;;
    -h | --help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
    esac
    shift
done

export PATH="$PATH:/usr/bin"
export PATH="$PATH:$HOME/.local/bin"

# install pip if not exists
if ! command -v python3 -m pip >/dev/null 2>&1
then
    echo "Installing pip"
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py --user
    rm get-pip.py
fi

# install ansible if not exists
if ! command -v ansible-playbook >/dev/null 2>&1
then
    echo "Installing ansible with pip"
    python3 -m pip install --user ansible
    export PATH="$PATH:~/.local/bin"
fi

# fetch playbook if not exists
PLAYBOOK_FILE=main.yaml
if $REMOVE_PACKAGES
then
    PLAYBOOK_FILE=rollback.yaml
fi

if ! ls $PLAYBOOK_FILE >/dev/null 2>&1
then
    echo "Retrieving playbook: $PLAYBOOK_FILE"
    wget -O ./$PLAYBOOK_FILE https://raw.githubusercontent.com/geertpingen/home/main/ansible/$PLAYBOOK_FILE
fi

# run playbook
echo "Running playbook: $PLAYBOOK_FILE"
ansible-playbook $PLAYBOOK_FILE
rm $PLAYBOOK_FILE
