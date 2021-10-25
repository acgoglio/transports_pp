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
for DIRECTION in 1 2 3; do
    sh transp_yr.sh $DIRECTION
done

##################################################
