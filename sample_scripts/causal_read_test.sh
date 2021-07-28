#!/bin/bash

######################################################################
### Simple Bash Script to test Causal Reads over a MariaDB Cluster ###
###                                                                ###
### Author: Catherine Trejo <catherine.trejo@mariadb.com>          ###
### Updated: Kester Riley <kester.riley@mariadb.com>               ###
### Version 1.1 July 2021                                          ###
######################################################################


######################################################################
### Make sure you enter the password you set for the labtest user  ###
######################################################################

PASSWORD="mariadb"

######################################################################
### This is the internal IP address of your Node 1 server          ###
######################################################################

NODE1="NODE-ONE-IP-ADDRESS"

######################################################################
### This is the internal IP address of your Node 2 server          ###
######################################################################

NODE2="NODE-TWO-IP-ADDRESS"

######################################################################
# Try replacing with 10000 to increase the amount of itterations   ###
######################################################################

ITTERATIONS=1000

######################################################################
### You should not need to change anything below this line         ###
######################################################################

FAILURES=0

function main {
  test_and_truncate
  i=1
  while [[  $i -le $ITTERATIONS ]]
  do
    echo -n -e "\nRound $i"
    mariadb -ulabtest -p$PASSWORD -h $NODE1 test -e"INSERT INTO t VALUES($i)" > /dev/null 2>&1 &
    ret=$(mariadb --batch -ulabtest -p$PASSWORD -h $NODE2 test -e"SELECT * FROM t WHERE id=$i")
    if [ "$ret" = "" ]; then
      echo -n " FAILED"
      FAILURES=$((FAILURES +1))
    fi
    ((i = i + 1))
  done
  echo -e "\n${FAILURES} causal read failures per $ITTERATIONS reads"
}

function test_and_truncate {
  #Ensure table exists and truncted before running script
  table_check=`mariadb -ulabtest -p$PASSWORD -h $NODE1 -bse  "SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 't' and TABLE_SCHEMA = 'test'"`
  if [ "$table_check" == "1" ]; then  echo "Table Exists"; mariadb -ulabtest -p$PASSWORD -h $NODE1 test -e"TRUNCATE test.t" > /dev/null 2>&1; else echo "The tabble does not exist, or can not be connected, please check the instructions."; exit; fi
}

main
