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
  source /users_home/oda/ag15419/transports_pp/transp_ana.ini

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
     sleep 1
     for TO_BE_RM in $( ls $ANA_WORKDIR/*.txt $ANA_WORKDIR/*.ini* ); do
         rm -v $TO_BE_RM
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
              if [[ ${YEARLY_FLAG} == 0 ]]; then 
                 grep "${ONLINE_SECTIONS}" ${ONLINE_INFILE}_allv.txt | grep "${POST_NAME}" | grep "total" | grep -v "2015"  >> online_${ONLINE_INFILE}${POST_NAME}.txt
              else
                 echo "Working on single year ${ANA_STARTDATE:0:4}"
                 grep "${ONLINE_SECTIONS}" ${ONLINE_INFILE}_allv.txt | grep "${POST_NAME}" | grep "total" | grep "${ANA_STARTDATE:0:4}"  >> online_${ONLINE_INFILE}${POST_NAME}.txt
              fi
              echo "NUMPERDAY= ${NUMPERDAY}"
              if [[ ${NUMPERDAY} == 1 ]]; then
                 echo "Adding HH:MM:SS to online_${ONLINE_INFILE}${POST_NAME}.txt file ..."
                 mv online_${ONLINE_INFILE}${POST_NAME}.txt online_${ONLINE_INFILE}${POST_NAME}.tmp
                 HH2ADD="12:00:00"
                 HH2ADD2WRITE="${HH2ADD}"
                 while read LINETOH; do
                      echo "${LINETOH:0:8} ${HH2ADD2WRITE} ${LINETOH:12:146}"
                 done<online_${ONLINE_INFILE}${POST_NAME}.tmp > online_${ONLINE_INFILE}${POST_NAME}.txt
              elif [[ ${NUMPERDAY} == 2 ]]; then
                 echo "Adding HH:MM:SS to online_${ONLINE_INFILE}${POST_NAME}.txt file ..."
                 mv online_${ONLINE_INFILE}${POST_NAME}.txt online_${ONLINE_INFILE}${POST_NAME}.tmp
                 HH2ADD="06:00:00"
                 HH2ADD2WRITE="${HH2ADD}"
                 while read LINETOH; do
                      echo "${LINETOH:0:8} ${HH2ADD2WRITE} ${LINETOH:12:146}"
                      if [[ ${HH2ADD} == "06:00:00" ]]; then
                         HH2ADD2WRITE="18:00:00"
                      elif [[ ${HH2ADD} == "18:00:00" ]]; then
                         HH2ADD2WRITE="06:00:00"
                      fi
                      HH2ADD="${HH2ADD2WRITE}"
                 done<online_${ONLINE_INFILE}${POST_NAME}.tmp > online_${ONLINE_INFILE}${POST_NAME}.txt
              fi 
            done
         done
         rm *_allv.txt
         ONLINE_COL_NUM=$(( ${ONLINE_DIRECTION} + 10 ))
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
       PP_FILE_1="${PP_INPATH_1}/${PP_FILES[0]}.nc"
       PP_FILE_2="${PP_INPATH_2}/${PP_FILES[1]}.nc"
       # Select dates 
       cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $PP_FILE_1 seldate1.nc
       cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $PP_FILE_2 seldate2.nc
       # Extract the values
       cdo outputtab,date,time,value,name seldate1.nc | grep "$PP_FIELD_1" | grep -v "1e+20" | grep -v "2015010" | sed -e "s/-//" | sed -e "s/-//" > pp1_volume_transport.txt
       cdo outputtab,date,time,value,name seldate2.nc | grep "$PP_FIELD_2" | grep -v "1e+20" | grep -v "2015010" | sed -e "s/-//" | sed -e "s/-//" > pp2_volume_transport.txt
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

          echo "PROVA ${FIT_FLAG}"
          # Plot gpl file
          echo "#" > ${GNUPLOT_TRA_TMP}
          echo "set term png size 1500,700 giant" >> ${GNUPLOT_TRA_TMP} #1300,800
          echo "set output \"$TRA_PLOT\" " >> ${GNUPLOT_TRA_TMP}
        
          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              NUM_LINES=$( wc -l ${TRA_ONLINE_TXT} | cut -f 1 -d" ")
              NUM_LINES=758 # TMP 1 yr 2 val per day
              echo "PROVA: $NUM_LINES"
              #echo "set timefmt \"%Y%m%d\" " >> ${GNUPLOT_TRA_TMP}
              echo "stats '$TRA_ONLINE_TXT' using ${ONLINE_COL_NUM} name 'STAT${TRA_ONLINE_POST}' nooutput" >> ${GNUPLOT_TRA_TMP}
              if [[ ${FIT_FLAG} == 1 ]]; then
                 if [[ ${NUMPERDAY} == 1 ]]; then
                    echo "fitf_${TRA_ONLINE_POST}(x)=y0${TRA_ONLINE_POST}+b${TRA_ONLINE_POST}*x+A_A${TRA_ONLINE_POST}*cos(0.01721421*x+phi_A${TRA_ONLINE_POST})+A_S${TRA_ONLINE_POST}*cos(0.034428413*x+phi_S${TRA_ONLINE_POST})" >> ${GNUPLOT_TRA_TMP}
                 elif [[ ${NUMPERDAY} == 2 ]]; then
                   echo "fitf_${TRA_ONLINE_POST}(x)=y0${TRA_ONLINE_POST}+b${TRA_ONLINE_POST}*x+A_A${TRA_ONLINE_POST}*cos(0.00861071*x+phi_A${TRA_ONLINE_POST})+A_S${TRA_ONLINE_POST}*cos(0.01721421*x+phi_S${TRA_ONLINE_POST})" >> ${GNUPLOT_TRA_TMP}
                 fi
                 echo "fit fitf_${TRA_ONLINE_POST}(x) 'online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt' using 0:${ONLINE_COL_NUM} via y0${TRA_ONLINE_POST},b${TRA_ONLINE_POST},A_A${TRA_ONLINE_POST},A_S${TRA_ONLINE_POST},phi_A${TRA_ONLINE_POST},phi_S${TRA_ONLINE_POST}" >> ${GNUPLOT_TRA_TMP}
              fi
          done

          echo "set title \"${ONLINE_INFILE} Time Series ( VAR: ${ONLINE_LONGNAME}  DT: $ANA_STARTDATE - $ANA_ENDDATE )\" " >> ${GNUPLOT_TRA_TMP}
          echo "set key opaque" >> ${GNUPLOT_TRA_TMP}
          echo "set xlabel \"Date\" " >> ${GNUPLOT_TRA_TMP}
          echo "set xdata time " >> ${GNUPLOT_TRA_TMP}
          echo "set timefmt \"%Y%m%d %H:%M:%S\" " >> ${GNUPLOT_TRA_TMP}
          echo "set xrange [\"${ANA_STARTDATE}\":\"${ANA_ENDDATE}\"] " >> ${GNUPLOT_TRA_TMP}
          echo "set format x \"%m/%Y\" " >> ${GNUPLOT_TRA_TMP}
          echo "set ylabel \"Transport [${PP_UDM}]\" " >> ${GNUPLOT_TRA_TMP}
          if [[ $FLAG_PLOT_TH == 1 ]]; then
             echo " set yrange [\"${PLOT_THMIN}\":\"${PLOT_THMAX}\"]" >> ${GNUPLOT_TRA_TMP}
          fi
          echo "set grid " >> ${GNUPLOT_TRA_TMP}
          echo "set key Left" >> ${GNUPLOT_TRA_TMP} # 
          echo "set key outside" >> ${GNUPLOT_TRA_TMP} 
          echo "set xzeroaxis lt 2 lc rgb \"black\" lw 3" >> ${GNUPLOT_TRA_TMP}
          if [[ ${FIT_FLAG} == 1 ]]; then
             echo "set xtics nomirror" >> ${GNUPLOT_TRA_TMP}
             echo "set x2tics" >> ${GNUPLOT_TRA_TMP}
             echo "set x2range [\"2\":\"${NUM_LINES}\"]" >> ${GNUPLOT_TRA_TMP}
          fi
          echo -en "plot" >> ${GNUPLOT_TRA_TMP}
          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              echo -en " '$TRA_ONLINE_TXT' using 1:${ONLINE_COL_NUM} with line lw 3 lt rgb '${ONLINE_COLOR}' title gprintf(\"Online${TRA_ONLINE_POST}  AVG = %g [${PP_UDM}]   \", STAT${TRA_ONLINE_POST}_mean)," >> ${GNUPLOT_TRA_TMP}
              if [[ ${FIT_FLAG} == 1 ]]; then
                 echo -en "fitf_${TRA_ONLINE_POST}(x) axes x2y1 with line lw 3 lt rgb '${ONLINE_COLOR_FIT}' title 'Online${TRA_ONLINE_POST} FIT'," >> ${GNUPLOT_TRA_TMP}
              fi 
          done
          if [[ ${ONLINE_SECTIONS} == "TRA_Gibraltar" ]]; then
             echo -en " STAT${TRA_ONLINE_POST}_mean with line lw 3 lt rgb '${ONLINE_COLOR_MEAN}' notitle," >> ${GNUPLOT_TRA_TMP}
          elif [[ ${ONLINE_SECTIONS} == "TRA_Sicily" ]]; then
             echo -en " STAT${TRA_ONLINE_POST}_mean with line lw 3 lt rgb '${ONLINE_COLOR_MEAN}' notitle," >> ${GNUPLOT_TRA_TMP}
          fi
          if [[ $OBS_FLAG == 1 ]]; then
             echo -en " ${OBS_VAL} with line lw 3 lt rgb '${OBS_COLOR}' title \"OBS Soto-Navarro = ${OBS_VAL} [${PP_UDM}]\"" >> ${GNUPLOT_TRA_TMP}
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
          echo "set term png size 1500,700 giant" >> ${GNUPLOT_TRA_TMP} #1300,800
          echo "set output \"$TRA_PLOT\" " >> ${GNUPLOT_TRA_TMP}

          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              #echo "set timefmt \"%Y%m%d\" " >> ${GNUPLOT_TRA_TMP}
              echo "stats '$TRA_ONLINE_TXT' using ${ONLINE_COL_NUM} name 'STAT${TRA_ONLINE_POST}' nooutput" >> ${GNUPLOT_TRA_TMP}
          done
          for TRA_PP_TXT in $( ls pp?_volume_transport.txt); do
              echo "stats '$TRA_PP_TXT' using 3 name 'STATP_${TRA_PP_TXT:2:1}' nooutput" >> ${GNUPLOT_TRA_TMP}
          done
          

          echo "set title \"${ONLINE_INFILE} Time Series ( VAR: ${ONLINE_LONGNAME}  DT: $ANA_STARTDATE - $ANA_ENDDATE )\" " >> ${GNUPLOT_TRA_TMP}
          echo "set key opaque" >> ${GNUPLOT_TRA_TMP}
          echo "set xlabel \"Date\" " >> ${GNUPLOT_TRA_TMP}
          echo "set xdata time " >> ${GNUPLOT_TRA_TMP}
          echo "set timefmt \"%Y%m%d %H:%M:%S\" " >> ${GNUPLOT_TRA_TMP}
          echo "set xrange [\"${ANA_STARTDATE}\":\"${ANA_ENDDATE}\"] " >> ${GNUPLOT_TRA_TMP}
          echo "set format x \"%m/%Y\" " >> ${GNUPLOT_TRA_TMP}
          echo "set ylabel \"Transport [${PP_UDM}]\" " >> ${GNUPLOT_TRA_TMP}
          echo "set grid " >> ${GNUPLOT_TRA_TMP}
          echo "set key Left" >> ${GNUPLOT_TRA_TMP} # 
          echo "set key outside" >> ${GNUPLOT_TRA_TMP}
          echo "set xzeroaxis lt 2 lc rgb \"black\" lw 3" >> ${GNUPLOT_TRA_TMP}
          #echo "set yrange [\"0.6\":\"1.2\"]" >> ${GNUPLOT_TRA_TMP}

          echo -en "plot" >> ${GNUPLOT_TRA_TMP}
          # ONLINE transports
          IDX_ON=0
          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              echo -en " '$TRA_ONLINE_TXT' using 1:${ONLINE_COL_NUM} with line lw 2 lt rgb '${ONLINE_COLOR[0]}' title \"Online${TRA_ONLINE_POST}\"," >> ${GNUPLOT_TRA_TMP}
              IDX_ON=$(( $IDX_ON + 1 ))
          done
          # PP transports
          IDX_PP=0
          for TRA_PP_TXT in $( ls pp?_volume_transport.txt); do
              echo -en " '$TRA_PP_TXT' using 1:3 with line lw 2 lt rgb '${PP_COLOR[$IDX_PP]}' title \"Postpr_${PP_INTAG[${IDX_PP}]}\"," >> ${GNUPLOT_TRA_TMP}
              IDX_PP=$(( $IDX_PP + 1 ))
          done
          # ONLINE mean
          if [[ ${ONLINE_SECTIONS} == "TRA_Gibraltar" ]]; then
             echo -en " STAT${TRA_ONLINE_POST}_mean with line lw 3 lt rgb '${ONLINE_COLOR_MEAN}' title gprintf(\"Online${TRA_ONLINE_POST}  AVG = %1.7g [${PP_UDM}]   \", STAT${TRA_ONLINE_POST}_mean)," >> ${GNUPLOT_TRA_TMP}
          elif [[ ${ONLINE_SECTIONS} == "TRA_Sicily" ]] || [[ ${ONLINE_SECTIONS} == "TRA_Messina" ]] ; then
             echo -en " STAT${TRA_ONLINE_POST}_mean with line lw 3 lt rgb '${ONLINE_COLOR_MEAN}' title gprintf(\"Online${TRA_ONLINE_POST}  AVG = %1.7g [${PP_UDM}]   \", STAT${TRA_ONLINE_POST}_mean)," >> ${GNUPLOT_TRA_TMP}
          fi
          # PP mean
          echo -en " STATP_1_mean with line lw 3 lt rgb '${PP_COLOR_MEAN}' title gprintf(\"Postpr_${PP_INTAG[${IDX_PP}]}  AVG = %1.7g [${PP_UDM}]   \", STATP_${TRA_PP_TXT:2:1}_mean) ," >> ${GNUPLOT_TRA_TMP}
          # Obs
          if [[ $OBS_FLAG == 1 ]]; then
             echo -en " ${OBS_VAL} with line lw 3 lt rgb '${OBS_COLOR}' title \"OBS Soto-Navarro = ${OBS_VAL} [${PP_UDM}]\"" >> ${GNUPLOT_TRA_TMP}
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
