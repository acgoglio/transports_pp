#!/bin/bash
#
# ACG 20/05/2021
# Script for transport comparisons  
# Ini file: transp_ana.ini 
#
#set -u
set -e
#set -x 
################### EXTRACT THE TRNSP ###################################

# start and end date
ANA_STARTDATE=$1
ANA_ENDDATE=$2

# Monthly run
for MM in 01 02 03 04 05 06 07 08 09 10 11 12; do

   for DIRECTION in 1 2 3; do
       echo "Working on Month $MM in $ANA_STARTDATE $ANA_ENDDATE"
       sh transp_yr.sh $DIRECTION $ANA_STARTDATE $ANA_ENDDATE $MM
   done
done


MM="all"
# Run
for DIRECTION in 1 2 3; do
    echo "Working on the whole period: $ANA_STARTDATE $ANA_ENDDATE"
    sh transp_yr.sh $DIRECTION $ANA_STARTDATE $ANA_ENDDATE $MM
done


##################################################
