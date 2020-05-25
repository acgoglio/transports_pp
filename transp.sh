#!/bin/bash
#
# ACG 22/05/2020
# Script for transport comparisons  
# Ini file: transp_ana.ini 
#
#set -u
set -e
#set -x 
################### PREPROC ###################################

# Source ini file
  source transp_ana.ini

# Set the environment
echo "Setting the environment: $TRA_MODULE"
module load $TRA_MODULE

# Read and check infos (work dir, file names, archive dir, etc.)

if [[ $ONLINE_FLAG == 1 ]] || [[ $PP_FLAG == 1 ]] ; then

  # Workdir check
  if [[ -d $ANA_WORKDIR ]]; then
     cd $ANA_WORKDIR
     echo "WORKDIR: $ANA_WORKDIR"
     cp ${SRC_DIR}/transp_ana.ini ${ANA_WORKDIR}/transp_ana.ini_$(date +%Y%m%d_%H%M%S)
     
     # Clean workdir
     echo "WARNING: I am going to remove all files in $ANA_WORKDIR ..."
     sleep 10
     for TO_BE_RM in $( ls $ANA_WORKDIR ); do
         rm $ANA_WORKDIR/$TO_BE_RM
         echo $TO_BE_RM
     done

  else
     echo "ERROR: WORKDIR $ANA_WORKDIR NOT FOUND!!"
     exit
  fi

 # File preproccessing
 if [[ $ONLINE_FLAG == 1 ]]; then
  echo "Working on online transports.."
  IDX_IN=0
  INSET_NUM=${#ONLINE_INPATHS[@]}
  while [[ $IDX_IN -lt $INSET_NUM ]]; do

    if [[ -d ${ONLINE_INPATHS[${IDX_IN}]} ]]; then
        for ONLINE_INFILE in ${ONLINE_INFILES[@]} ; do
              echo "Concatenating online transport infiles: $ONLINE_INFILE"
              cat ${ONLINE_INPATHS[${IDX_IN}]}/${ONLINE_INFILE}* > ${ONLINE_INFILE}_allv.txt || echo "NOT Found infile: $ONLINE_INFILE in path: ${ONLINE_INPATHS[$IDX_IN]}"
              for POST_NAME in ${ONLINE_SECTIONS_POST[@]}; do
                 grep "${ONLINE_SECTIONS}" ${ONLINE_INFILE}_allv.txt | grep "${POST_NAME}" | grep "total" | grep -v "2015010"  >> online_${ONLINE_INFILE}${POST_NAME}.txt
              done
         done
         rm *_allv.txt
         ONLINE_COL_NUM=$(( ${ONLINE_DIRECTION} + 9 ))
    else 
      echo "ERROR: Input dir ${ANA_INPATHS[${IDX_IN}]} NOT FOUND!!"
      exit
    fi

  IDX_IN=$(( $IDX_IN + 1 ))
  done
 fi

 if [[ $PP_FLAG == 1 ]] ; then
    NUM_PP_FILES=${#PP_FILES[@]}

    if [[ ${#PP_FILES[@]} == 1 ]] ; then
       PP_FILE="${PP_INPATH_1}/${PP_FILES}.nc"
       # Select dates 
       cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $PP_FILE seldate1.nc
       # Extract the values
       cdo outputtab,date,time,value,name seldate1.nc | grep "$PP_FIELD" | grep -v "1e+20" | grep -v "2015010" | sed -e "s/-//" | sed -e "s/-//" > pp1_volume_transport.txt

    elif [[ ${#PP_FILES[@]} == 2 ]] ; then
       PP_FILE_1="${PP_INPATH_1}/${PP_FILES[1]}.nc"
       PP_FILE_2="${PP_INPATH_2}/${PP_FILES[2]}.nc"
       # Select dates 
       cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $PP_FILE_1 seldate1.nc
       cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $PP_FILE_2 seldate2.nc
       # Extract the values
       cdo outputtab,date,time,value,name seldate1.nc | grep "$PP_FIELD_1" | grep -v "1e+20" | grep -v "2015010" > pp1_volume_transport.txt
       cdo outputtab,date,time,value,name seldate1.nc | grep "$PP_FIELD_2" | grep -v "1e+20" | grep -v "2015010" > pp2_volume_transport.txt
    else
         echo "Too many PP_INFILES: max 2!!!"
         exit
    fi
 fi
fi
####################### PLOTS ###############################
if [[ $ONLINE_FLAG == 1 ]] && [[ $PP_FLAG == 0 ]] ; then

          TRA_PLOT=$( echo "$TRA_PLOT_TPL" | sed -e "s/%SECTION%/${ONLINE_SECTIONS}/g"  -e "s/%DATES%/"${ANA_STARTDATE}_${ANA_ENDDATE}"/g" -e "s/%DIRECTION%/${ONLINE_DIRECTION_MEAN:0:1}/g" )
          echo "Out Plot: $TRA_PLOT"

          GNUPLOT_TRA_TMP="tra_tmp.gpl"

          # Plot gpl file
          echo "#" > ${GNUPLOT_TRA_TMP}
          echo "set term jpeg size 1500,700 giant" >> ${GNUPLOT_TRA_TMP} #1300,800
          echo "set output \"$TRA_PLOT\" " >> ${GNUPLOT_TRA_TMP}
        
          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              #echo "set timefmt \"%Y%m%d\" " >> ${GNUPLOT_TRA_TMP}
              echo "stats '$TRA_ONLINE_TXT' using ${ONLINE_COL_NUM} name 'STAT${TRA_ONLINE_POST}' nooutput" >> ${GNUPLOT_TRA_TMP}
          done

          echo "set title \"${ONLINE_INFILE} Time Series ( VAR: ${ONLINE_LONGNAME}  DT: $ANA_STARTDATE - $ANA_ENDDATE )\" " >> ${GNUPLOT_TRA_TMP}
          echo "set key opaque" >> ${GNUPLOT_TRA_TMP}
          echo "set xlabel \"Date\" " >> ${GNUPLOT_TRA_TMP}
          echo "set xdata time " >> ${GNUPLOT_TRA_TMP}
          echo "set timefmt \"%Y%m%d\" " >> ${GNUPLOT_TRA_TMP}
          echo "set xrange [\"${ANA_STARTDATE}\":\"${ANA_ENDDATE}\"] " >> ${GNUPLOT_TRA_TMP}
          echo "set format x \"%d/%m/%Y\" " >> ${GNUPLOT_TRA_TMP}
          echo "set ylabel \"Transport [Sv]\" " >> ${GNUPLOT_TRA_TMP}
          echo "set grid " >> ${GNUPLOT_TRA_TMP}
          echo "set key Left" >> ${GNUPLOT_TRA_TMP} # 
          echo "set key outside" >> ${GNUPLOT_TRA_TMP} 
          echo "set xzeroaxis lt 2 lc rgb \"black\" lw 3" >> ${GNUPLOT_TRA_TMP}

          echo -en "plot" >> ${GNUPLOT_TRA_TMP}
          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              echo -en " '$TRA_ONLINE_TXT' using 1:${ONLINE_COL_NUM} with line lw 3 lt rgb '${ONLINE_COLOR}' title gprintf(\"Online${TRA_ONLINE_POST}  AVG = %g [Sv]   \", STAT${TRA_ONLINE_POST}_mean)," >> ${GNUPLOT_TRA_TMP}
          done
          echo -en " STAT5_48_mean with line lw 3 lt rgb '${ONLINE_COLOR}' notitle," >> ${GNUPLOT_TRA_TMP}
          if [[ $OBS_FLAG == 1 ]]; then
             echo -en " ${OBS_VAL} with line lw 3 lt rgb '${OBS_COLOR}' title \"OBS Soto-Navarro = ${OBS_VAL} [Sv]\"" >> ${GNUPLOT_TRA_TMP}
          fi
          # Plot
          gnuplot < $GNUPLOT_TRA_TMP  || echo "Prob with this plot..why?!"
          #rm -v $GNUPLOT_TRA_TMP


elif [[ $ONLINE_FLAG == 1 ]] && [[ $PP_FLAG == 1 ]] ; then

          TRA_PLOT=$( echo "$TRA_PLOT_TPL" | sed -e "s/%SECTION%/${ONLINE_SECTIONS}/g"  -e "s/%DATES%/"${ANA_STARTDATE}_${ANA_ENDDATE}"/g" -e "s/%DIRECTION%/${ONLINE_DIRECTION_MEAN:0:1}/g" )
          echo "Out Plot: $TRA_PLOT"

          GNUPLOT_TRA_TMP="tra_tmp.gpl"

          # Plot gpl file
          echo "#" > ${GNUPLOT_TRA_TMP}
          echo "set term jpeg size 1500,700 giant" >> ${GNUPLOT_TRA_TMP} #1300,800
          echo "set output \"$TRA_PLOT\" " >> ${GNUPLOT_TRA_TMP}

          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              #echo "set timefmt \"%Y%m%d\" " >> ${GNUPLOT_TRA_TMP}
              echo "stats '$TRA_ONLINE_TXT' using ${ONLINE_COL_NUM} name 'STAT${TRA_ONLINE_POST}' nooutput" >> ${GNUPLOT_TRA_TMP}
          done
          for TRA_PP_TXT in $( ls pp?_volume_transport.txt); do
              echo "stats '$TRA_PP_TXT' using 3 name 'STAT_${TRA_PP_TXT:2:1}' nooutput" >> ${GNUPLOT_TRA_TMP}
          done
          

          echo "set title \"${ONLINE_INFILE} Time Series ( VAR: ${ONLINE_LONGNAME}  DT: $ANA_STARTDATE - $ANA_ENDDATE )\" " >> ${GNUPLOT_TRA_TMP}
          echo "set key opaque" >> ${GNUPLOT_TRA_TMP}
          echo "set xlabel \"Date\" " >> ${GNUPLOT_TRA_TMP}
          echo "set xdata time " >> ${GNUPLOT_TRA_TMP}
          echo "set timefmt \"%Y%m%d\" " >> ${GNUPLOT_TRA_TMP}
          echo "set xrange [\"${ANA_STARTDATE}\":\"${ANA_ENDDATE}\"] " >> ${GNUPLOT_TRA_TMP}
          echo "set format x \"%d/%m/%Y\" " >> ${GNUPLOT_TRA_TMP}
          echo "set ylabel \"Transport [Sv]\" " >> ${GNUPLOT_TRA_TMP}
          echo "set grid " >> ${GNUPLOT_TRA_TMP}
          echo "set key Left" >> ${GNUPLOT_TRA_TMP} # 
          echo "set key outside" >> ${GNUPLOT_TRA_TMP}
          echo "set xzeroaxis lt 2 lc rgb \"black\" lw 3" >> ${GNUPLOT_TRA_TMP}

          echo -en "plot" >> ${GNUPLOT_TRA_TMP}
          IDX_PP=0
          for TRA_PP_TXT in $( ls pp?_volume_transport.txt); do
              echo -en " '$TRA_PP_TXT' using 1:3 with line lw 3 lt rgb '${PP_COLOR}' title gprintf(\"Postpr_${PP_INTAG[${IDX_PP}]}  AVG = %1.7g [Sv]   \", STAT_${TRA_PP_TXT:2:1}_mean)," >> ${GNUPLOT_TRA_TMP}
              IDX_PP=$(( $IDX_PP + 1 ))
          done
          echo -en " STAT_${TRA_PP_TXT:2:1}_mean with line lw 3 lt rgb '${PP_COLOR}' notitle," >> ${GNUPLOT_TRA_TMP}
          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              echo -en " '$TRA_ONLINE_TXT' using 1:${ONLINE_COL_NUM} with line lw 3 lt rgb '${ONLINE_COLOR}' title gprintf(\"Online_${TRA_ONLINE_POST}  AVG = %1.7g [Sv]   \", STAT${TRA_ONLINE_POST}_mean)," >> ${GNUPLOT_TRA_TMP}
          done
          echo -en " STAT5_48_mean with line lw 3 lt rgb '${ONLINE_COLOR}' notitle," >> ${GNUPLOT_TRA_TMP}
          if [[ $OBS_FLAG == 1 ]]; then
             echo -en " ${OBS_VAL} with line lw 3 lt rgb '${OBS_COLOR}' title \"OBS Soto-Navarro = ${OBS_VAL} [Sv]\"" >> ${GNUPLOT_TRA_TMP}
          fi
          # Plot
          gnuplot < $GNUPLOT_TRA_TMP  || echo "Prob with this plot..why?!"
          #rm -v $GNUPLOT_TRA_TMP

fi
#
#
####################### POSTPROC ###########################
#
## Output check
#
## Archive
#
#
