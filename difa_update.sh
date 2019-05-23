#!/bin/bash

BLOCK_DIR=

#setup auto starting
#remove old one
if [ -f /lib/systemd/system/snowgem.service ]; then
	sudo systemctl disable --now snowgem.service
else
	echo "File not existed, OK"
  #create new one
  username=$(whoami)
  echo $username

  service=
  if [ "$username" = "root" ] ; then
    service="echo '[Unit]
Description=Snowgem daemon
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/root/snowgemd
WorkingDirectory=/root/.snowgem
User=root
KillMode=mixed
Restart=always
RestartSec=10
TimeoutStopSec=10
Nice=-20
ProtectSystem=full

[Install]
WantedBy=multi-user.target' >> /lib/systemd/system/snowgem.service"
  else
    service="echo '[Unit]
Description=Snowgem daemon
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/home/'$username'/snowgemd
WorkingDirectory=/home/'$username'/.snowgem
User='$username'
KillMode=mixed
Restart=always
RestartSec=10
TimeoutStopSec=10
Nice=-20
ProtectSystem=full

[Install]
WantedBy=multi-user.target' >> /lib/systemd/system/snowgem.service"
  fi
  echo $service
  sudo sh -c "$service"
fi

killall -9 snowgemd

#remove old params files
if [ -d ~/.snowgem-params ]; then
  rm ~/.snowgem-params -r
fi

if [ -d ~/snowgem-wallet ]; then
  rm ./snowgem-wallet -r
fi

chmod +x ~/masternode-upgrade/fetch-params.sh

wget -N https://github.com/Snowgem/Snowgem/releases/download/3000452-20190520/snowgem-ubuntu16.04-3000452-20190520.zip -O ~/binary.zip
unzip -o ~/binary.zip -d ~

if [ ! -d ~/.snowgem/blocks ]; then
  wget -N https://github.com/Snowgem/Data/releases/download/0.0.1/blockchain_snowgem_index.zip.sf-part1 -O ~/bc.sf-part1
  wget -N https://github.com/Snowgem/Data/releases/download/0.0.1/blockchain_snowgem_index.zip.sf-part2 -O ~/bc.sf-part2
  wget -N https://github.com/Snowgem/Data/releases/download/0.0.1/blockchain_snowgem_index.zip.sf-part3 -O ~/bc.sf-part3
  wget -N https://github.com/Snowgem/Data/releases/download/0.0.1/blockchain_snowgem_index.zip.sf-part4 -O ~/bc.sf-part4
  cd ~
  cat *.*part* > blockchain.zip
  rm ~/bc.sf-part1
  rm ~/bc.sf-part2
  rm ~/bc.sf-part3
  rm ~/bc.sf-part4
  unzip -o ~/blockchain.zip -d ~/.snowgem
  rm ~/blockchain.zip
fi


cd ~

./masternode-upgrade/fetch-params.sh

chmod +x ~/snowgemd ~/snowgem-cli

#start
./snowgemd -daemon
sudo systemctl enable --now snowgem.service

sleep 11s
x=1
counter=1
echo "Wait for starting"
while true ; do
    echo "Wallet is opening, please wait. This step will take few minutes ($x)"
    sleep 1s
    x=$(( $x + 1 ))
    ./snowgem-cli getinfo &> text.txt
    line=$(tail -n 1 text.txt)
    if [[ $line == *"..."* ]]; then
        echo $line
    fi
    if [[ $(tail -n 1 text.txt) == *"sure server is running"* ]]; then
        counter=$(( $counter + 1 ))
        if [[ $counter == 10 ]]; then
            echo "Cannot start wallet, please contact us on Discord(https://discord.gg/7a7XRZr) for help"
            break
        fi
    fi
    if [[ $(head -n 20 text.txt) == *"version"*  ]]; then
        echo "Checking masternode status"
        while true ; do
            echo "Please wait ($x)"
            sleep 1s
            x=$(( $x + 1 ))
            ./snowgem-cli masternodedebug &> text.txt
            line=$(head -n 1 text.txt)
	    echo $line
            if [[ $line == *"Masternode successfully started"* ]]; then
                ./snowgem-cli masternodedebug
                break
            fi
        done
        ./snowgem-cli getinfo
        ./snowgem-cli masternodedebug
        break

    fi
done
