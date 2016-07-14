#!/bin/bash

# Prerequisites
sudo apt-get update
sudo apt-get install lua5.1 liblua5.1-0-dev unzip libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential mysql-server -y   # Make sure you note your MySQL password!
# OpenResty
cd ..
wget https://openresty.org/download/openresty-1.9.7.5.tar.gz   # Install a later version if available!
tar xvf openresty-1.9.7.5.tar.gz
cd openresty-1.9.7.5
./configure
make
sudo make install
cd ..
# LuaRocks
wget https://keplerproject.github.io/luarocks/releases/luarocks-2.3.0.tar.gz # Install a later version if available!
tar xvf luarocks-2.3.0.tar.gz
cd luarocks-2.3.0
./configure
make build
sudo make install
sudo luarocks install lapis
sudo luarocks install moonscript
cd ..
rm -rf openresty*
rm -rf luarucks*
cd slackive
cp ./secret.moon.example ./secret.moon
nano ./secret.moon   # Put the info needed in there!
moonc .
lapis migrate production
lapis server production
