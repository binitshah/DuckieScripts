#!/bin/bash

set -e

echo "checking running on an ubuntu 20.04 machine"
source /etc/os-release
if [[ ! $VERSION_ID = "20.04" ]]; then
    echo "not running on an ubuntu 20.04 machine. exiting."
    exit 1
fi
echo "yes"
echo ""

echo "checking running script from correct folder"
if [[ ! "$PWD" =~ duckie_scripts ]]; then
    echo "run this script from the duckie_scripts folder. exiting."
    exit 1
fi
echo "yes"
echo ""

echo "waiting to get online"
while ! timeout 0.2 ping -c 1 -n google.com &> /dev/null
do
    sleep 1
    printf "%c" "."
done
echo "online!"
echo ""

echo "checking install repo is up-to-date"
git remote update
UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
if [ ! $LOCAL = $REMOTE ]; then
    echo "repo not up-to-date. perform a 'git pull'. exiting."
    exit 1
fi
echo ""

echo "waiting for apt lock"
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
    sleep 1
    printf "%c" "."
done
echo "got apt lock!"
echo ""

echo "running an apt update & upgrade"
sudo apt update
sudo apt upgrade --yes
echo ""

echo "Setting locale info"
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
echo ""

echo "installing ROS2 prereqs"
sudo apt install --yes curl gnupg2 lsb-release
echo ""

echo "adding ROS apt key"
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
echo ""

echo "adding ROS2 repos to sources list"
sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'
echo ""

echo "installing ROS2"
sudo apt update
sudo apt install --yes ros-foxy-desktop ros-foxy-demo-nodes-cpp ros-foxy-demo-nodes-py
echo ""

echo "installing argcomplete"
sudo apt install --yes python3-pip
pip3 install -U argcomplete
echo ""

echo "adding setup.bash to bashrc"
echo "" >> ~/.bashrc
echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc
echo ""

echo "installing terminator, zip, eog, & i2c-tools"
sudo apt install --yes terminator eog zip i2c-tools
echo ""

echo "installing Arduino"
sudo snap install arduino
sudo usermod -a -G tty $USER
echo ""

echo "setting vim settings in vimrc"
cp ./.vimrc ~/
echo ""

echo "disable cloud-init to reduce boot time"
sudo touch /etc/cloud/cloud-init.disabled
echo ""

echo "disable snapd to reduce boot time"
sudo apt purge --yes snapd
rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd
echo ""

echo "disable MOTD news"
sudo cp ./motd-news /etc/default/motd-news
echo ""

echo "you will need to install the ATTinyCore manually using the arduino IDE"
echo ""
