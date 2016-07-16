#!/bin/bash

# Prerequisites
echo "Please set up certificates before continuing."
read -p " Press [Enter] to continue, or Ctrl+C to cancel."
sudo apt-get update
sudo apt-get install wget curl lua5.1 liblua5.1-0-dev unzip libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential mysql-server libmysql++-dev -y   # Make sure you note your MySQL password!
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
# some rocks
sudo luarocks install lapis
sudo luarocks install moonscript
sudo luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql
# cleanup
cd ..
rm -rf openresty*
rm -rf luarocks*
# okay now let's set it up
cd slackiver
cp secret.moon.example secret.moon
nano secret.moon   # Put the info needed in there!
moonc .
echo "Logging into MySQL (using root)..."
echo "Do 'CREATE DATABASE slackiver;' then 'exit' !"
mysql -u root -p
lapis migrate production
lapis server production
