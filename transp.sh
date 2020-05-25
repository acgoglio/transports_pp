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
          echo "set term jpeg size 1200,600 giant" >> ${GNUPLOT_TRA_TMP} #1300,800
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
          #echo "set key left top" >> ${GNUPLOT_TRA_TMP} # 
          echo "set key outside" >> ${GNUPLOT_TRA_TMP} 
          echo "set xzeroaxis lt 2 lc rgb \"black\" lw 3" >> ${GNUPLOT_TRA_TMP}

          echo -en "plot" >> ${GNUPLOT_TRA_TMP}
          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              echo -en " '$TRA_ONLINE_TXT' using 1:${ONLINE_COL_NUM} with line lw 3 lt rgb '${ONLINE_COLOR}' title gprintf(\"Online${TRA_ONLINE_POST} (AVG = %g [Sv] ) \", STAT${TRA_ONLINE_POST}_mean)," >> ${GNUPLOT_TRA_TMP}
          done
          echo -en " STAT_48_mean with line lw 3 lt rgb '${ONLINE_COLOR}' notitle," >> ${GNUPLOT_TRA_TMP}
          if [[ $OBS_FLAG == 1 ]]; then
             echo -en " ${OBS_VAL} with line lw 3 lt rgb '${OBS_COLOR}' title \"OBS [Soto-Navarro] = ${OBS_VAL} [Sv]\"" >> ${GNUPLOT_TRA_TMP}
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
          echo "set term jpeg size 1500,500 giant" >> ${GNUPLOT_TRA_TMP} #1300,800
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
          #echo "set key left top" >> ${GNUPLOT_TRA_TMP} # 
          echo "set key outside" >> ${GNUPLOT_TRA_TMP}
          echo "set xzeroaxis lt 2 lc rgb \"black\" lw 3" >> ${GNUPLOT_TRA_TMP}

          echo -en "plot" >> ${GNUPLOT_TRA_TMP}
          IDX_PP=0
          for TRA_PP_TXT in $( ls pp?_volume_transport.txt); do
              echo -en " '$TRA_PP_TXT' using 1:3 with line lw 3 lt rgb '${PP_COLOR}' title gprintf(\"Postpr_${PP_INTAG[${IDX_PP}]} (AVG = %g [Sv] ) \", STAT_${TRA_PP_TXT:2:1}_mean)," >> ${GNUPLOT_TRA_TMP}
              IDX_PP=$(( $IDX_PP + 1 ))
          done
          echo -en " STAT_${TRA_PP_TXT:2:1}_mean with line lw 3 lt rgb '${PP_COLOR}' notitle," >> ${GNUPLOT_TRA_TMP}
          for TRA_ONLINE_POST in ${ONLINE_SECTIONS_POST[@]} ; do
              TRA_ONLINE_TXT=online_${ONLINE_INFILE}${TRA_ONLINE_POST}.txt
              echo -en " '$TRA_ONLINE_TXT' using 1:${ONLINE_COL_NUM} with line lw 3 lt rgb '${ONLINE_COLOR}' title gprintf(\"Online${TRA_ONLINE_POST} (AVG = %g [Sv] ) \", STAT${TRA_ONLINE_POST}_mean)," >> ${GNUPLOT_TRA_TMP}
          done
          echo -en " STAT_48_mean with line lw 3 lt rgb '${ONLINE_COLOR}' notitle," >> ${GNUPLOT_TRA_TMP}
          if [[ $OBS_FLAG == 1 ]]; then
             echo -en " ${OBS_VAL} with line lw 3 lt rgb '${OBS_COLOR}' title \"OBS [Soto-Navarro] = ${OBS_VAL} [Sv]\"" >> ${GNUPLOT_TRA_TMP}
          fi
          # Plot
          gnuplot < $GNUPLOT_TRA_TMP  || echo "Prob with this plot..why?!"
          #rm -v $GNUPLOT_TRA_TMP

fi
#
#
#
## Caso con pp da ricavare da qui sotto..
# if [[ $_FLAG == 1 ]]; then
#    echo "Mydiag analysis.."
#
#    IDX_=0
#    for _FIELD in ${MYDIAG_SHORT_NAMES[@]}; do
#      #if [[ $IDX_ != 2 ]] && [[ $IDX_MYDIAG != 5 ]] && [[ $IDX_MYDIAG != 8 ]] && [[ $IDX_MYDIAG != 11 ]] && [[ $IDX_MYDIAG != 14 ]] && [[ $IDX_MYDIAG != 25 ]] && [[ $IDX_MYDIAG != 33 ]] && [[ $IDX_MYDIAG != 35 ]]; then
#        echo "$IDX_ ) I am working on ${MYDIAG_SHORT_NAMES[${IDX_MYDIAG}]}.."
#
#        # Infiles
#        _FILE_1="${MYDIAG_PATH_1}/${MYDIAG_FILES[${IDX_MYDIAG}]}.nc"
#        _FILE_2="${MYDIAG_PATH_2}/${MYDIAG_FILES[${IDX_MYDIAG}]}.nc"
#         
#        #     
#        if [[ -f $_FILE_1 ]] && [[ -f $MYDIAG_FILE_2 ]] ; then
#
#          # Select dates 
#          cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $_FILE_1 seldate1.nc
#          cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $_FILE_2 seldate2.nc
#
#          # Compute the difference 
#          _DIFFOUT="Diff_${MYDIAG_FIELD}.nc"
#          cdo sub seldate1.nc seldate2.nc $_DIFFOUT 
#
#          # Extract TS
#          _PLOTINFILE_1="plotinfile_1_${MYDIAG_FIELD}.txt"
#          _PLOTINFILE_2="plotinfile_2_${MYDIAG_FIELD}.txt"
#          _PLOTINFILE_DIFF="plotinfile_diff_${MYDIAG_FIELD}.txt"
#
#          # The following two line should be RM 
#          #cdo outputtab,date,time,value,name $_FILE_1 | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_1 
#          #cdo outputtab,date,time,value,name $_FILE_2 | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_2
#          # 
#          cdo outputtab,date,time,value,name seldate1.nc | grep "$_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_1 
#          cdo outputtab,date,time,value,name seldate2.nc | grep "$_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_2
#
#          cdo outputtab,date,time,value,name $_DIFFOUT | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_DIFF
#         
#
#          # Plot TS and Diff
#          PLOT_SDATE=$ANA_STARTDATE
#          PLOT_EDATE=$ANA_ENDDATE
#
#          _PLOTUDM=${MYDIAG_UDM[${IDX_MYDIAG}]} 
#
#          _PLOT=$( echo "$MYDIAG_PLOT_TPL" | sed -e "s/%FIELD%/${MYDIAG_FILES[${IDX_MYDIAG}]}/g"  -e "s/%DATES%/"${PLOT_SDATE}_${PLOT_EDATE}"/g" )
#          echo "_PLOT_TPL $MYDIAG_PLOT"
#
#
#          GNUPLOT__TMP="mydiag_tmp.gpl_${MYDIAG_FILES[${IDX_MYDIAG}]}"
#          #GNUPLOT__TMPTXT="mydiag_tmptxt.gpl"
#
#
#          ## Txt gpl file
#          #echo "#" > ${GNUPLOT__TMPTXT}
#          #echo "set term jpeg giant size 1800,900 font \"Times,45\"" >> ${GNUPLOT__TMPTXT}
#          #echo "set output \"$_PLOT\" " >> ${GNUPLOT_MYDIAG_TMPTXT}
#
#          #echo "stats '$_PLOTINFILE_1' using 3 name 'STATS1'" >> ${GNUPLOT_MYDIAG_TMPTXT}
#          #echo "stats '$_PLOTINFILE_2' using 3 name 'STATS2'" >> ${GNUPLOT_MYDIAG_TMPTXT}
#          #echo "stats '$_PLOTINFILE_DIFF' using 3 name 'STATSD'" >> ${GNUPLOT_MYDIAG_TMPTXT}
#
#          # Plot gpl file
#          echo "#" > ${GNUPLOT__TMP}
#          echo "set term jpeg size 1200,600 giant" >> ${GNUPLOT__TMP} #1300,800
#          echo "set output \"$_PLOT\" " >> ${GNUPLOT_MYDIAG_TMP}
#
#          echo "stats '$_PLOTINFILE_1' using 3 name 'STATS1' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#          echo "stats '$_PLOTINFILE_2' using 3 name 'STATS2' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#          echo "stats '$_PLOTINFILE_DIFF' using 3 name 'STATSD' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#
#          echo "set multiplot layout 2,1 title \"Time Series ( VAR: ${_LONG_NAMES[${IDX_MYDIAG}]}  DT: $ANA_STARTDATE - $ANA_ENDDATE )\" " >> ${GNUPLOT_MYDIAG_TMP}
#
#          echo "set key opaque" >> ${GNUPLOT__TMP}
#          echo "set xlabel \"Time\" " >> ${GNUPLOT__TMP}
#          echo "set xdata time " >> ${GNUPLOT__TMP}
#          echo "set timefmt \"%Y-%m-%d %H:%M:%S\" " >> ${GNUPLOT__TMP}
#          echo "set xrange [\"${PLOT_SDATE:0:4}-${PLOT_SDATE:4:2}-${PLOT_SDATE:6:2} 00:00:00\":\"${PLOT_EDATE:0:4}-${PLOT_EDATE:4:2}-${PLOT_EDATE:6:2} 23:30:00\"] " >> ${GNUPLOT__TMP}
#          echo "set format x \"%d/%m/%Y\" " >> ${GNUPLOT__TMP}
#          #echo "set ylabel \"${_FIELD} ${MYDIAG_PLOTUDM}\" " >> ${GNUPLOT_MYDIAG_TMP}
#          echo "set grid " >> ${GNUPLOT__TMP}
#          echo "set key left top" >> ${GNUPLOT__TMP} # right bottom
#          echo "set xzeroaxis lt 2 lc rgb \"black\" lw 3" >> ${GNUPLOT__TMP}
#
#          # All:
#          #echo "plot '$_PLOTINFILE_1' using 1:3 with line lw 3 lt rgb \"${MYDIAG_COLOR1}\" title gprintf(\"${MYDIAG_INTAG_1} (AVG = %g ${MYDIAG_PLOTUDM} ) \", STATS1_mean), '$MYDIAG_PLOTINFILE_2' using 1:3 with line lw 3 lt rgb \"${MYDIAG_COLOR2}\" title gprintf(\"${MYDIAG_INTAG_2} (AVG = %g ${MYDIAG_PLOTUDM} )\", STATS2_mean) " >> ${GNUPLOT_MYDIAG_TMP}
#          # All no avg:
#          echo "set ylabel \"${_LONG_NAMES[${IDX_MYDIAG}]} ${MYDIAG_PLOTUDM}\" " >> ${GNUPLOT_MYDIAG_TMP}
#          echo "plot '$_PLOTINFILE_1' using 1:3 with line lw 3 lt rgb \"${MYDIAG_COLOR1}\" title \"${MYDIAG_INTAG_1}\", '$MYDIAG_PLOTINFILE_2' using 1:3 with line lw 3 lt rgb \"${MYDIAG_COLOR2}\" title \"${MYDIAG_INTAG_2}" >> ${GNUPLOT_MYDIAG_TMP} 
#          # SSH:
#          #echo "plot STATS1_mean lw 2 lc rgb \"cyan\" title gprintf( \"AVG ${_INTAG_1}=%g ${MYDIAG_PLOTUDM}\", STATS1_mean ), STATS2_mean lw 2 lc rgb \"gray\" title gprintf( \"AVG ${MYDIAG_INTAG_2}=%g ${MYDIAG_PLOTUDM}\", STATS2_mean ),'$MYDIAG_PLOTINFILE_1' using 1:3 with line lw 2 lt rgb \"blue\" title gprintf(\"${MYDIAG_INTAG_1}\", STATS1_mean), '$MYDIAG_PLOTINFILE_2' using 1:3 with line lw 2 lt rgb \"black\" title gprintf(\"${MYDIAG_INTAG_2}\", STATS2_mean)" >> ${GNUPLOT_MYDIAG_TMP}
#          # The following 2 lines should be REMOVED (written for compaison with Cucco 2016, transprts at Messina strait comparison)
#          #echo "set yrange [\"-0.5\":\"0.6\"] " >> ${GNUPLOT__TMP}
#          #echo "plot '$_PLOTINFILE_1' using 1:3 with line lw 2 lt rgb \"black\" title gprintf(\"${MYDIAG_INTAG_1} (AVG = %g ${MYDIAG_PLOTUDM} ) \", STATS1_mean), '$MYDIAG_PLOTINFILE_2' using 1:3 with line lw 2 lt rgb \"red\" title gprintf(\"${MYDIAG_INTAG_2} (AVG = %g ${MYDIAG_PLOTUDM} )\", STATS2_mean) " >> ${GNUPLOT_MYDIAG_TMP}
#          # All:
#          #echo "plot '$_PLOTINFILE_DIFF' using 1:3 with line lw 2 lt rgb \"dark-green\" title \"Diff: ${MYDIAG_INTAG_1} - ${MYDIAG_INTAG_2}\", STATSD_mean lw 2 lc rgb \"gray\" title gprintf( \"${MYDIAG_INTAG_1}-${MYDIAG_INTAG_2} mean = %g ${MYDIAG_PLOTUDM} \", STATSD_mean ), STATSD_lo_quartile lw 2 lc rgb \"green\" title \"${MYDIAG_INTAG_1}-${MYDIAG_INTAG_2} 1st quartile\",STATSD_up_quartile lw 2 lc rgb \"green\" title \"${MYDIAG_INTAG_1}-${MYDIAG_INTAG_2} 3rd quartile\"  " >> ${GNUPLOT_MYDIAG_TMP}
#        # SSH
#        echo "set ylabel \" Differences ${_PLOTUDM}\"" >> ${GNUPLOT_MYDIAG_TMP}
#        echo "set yrange [\"-0.008\":\"0.008\"]" >> ${GNUPLOT__TMP}
#        #echo "plot '$_PLOTINFILE_DIFF' using 1:3 with line lw 2 lt rgb \"${MYDIAG_DIFFCOLOR1}\" title \"${MYDIAG_INTAG_1} - ${MYDIAG_INTAG_2}\", STATSD_mean lw 2 lc rgb \"${MYDIAG_AVG_DIFFCOLOR1}\" title gprintf( \"AVG Diff = %g ${MYDIAG_PLOTUDM} \", STATSD_mean )" >> ${GNUPLOT_MYDIAG_TMP} 
#        echo "plot '$_PLOTINFILE_DIFF' using 1:3 with line lw 2 lt rgb \"${MYDIAG_DIFFCOLOR1}\" title \"${MYDIAG_INTAG_1} - ${MYDIAG_INTAG_2}\", STATSD_max lw 0 lc rgb \"${MYDIAG_AVG_DIFFCOLOR1}\" title gprintf( \"MAX Diff = %g [cm/s] \", STATSD_max*100 ), STATSD_mean lw 2 lc rgb \"${MYDIAG_AVG_DIFFCOLOR1}\" title gprintf( \"AVG Diff = %g [cm/s] \", STATSD_mean*100 ), STATSD_min lw 0 lc rgb \"${MYDIAG_AVG_DIFFCOLOR1}\" title gprintf( \"MIN Diff = %g [cm/s] \", STATSD_min*100 ) " >> ${GNUPLOT_MYDIAG_TMP}
#
#        ## Write statistics
#        #gnuplot < $GNUPLOT__TMPTXT || echo "Prob with stat..why?!"
#        # Plot
#        gnuplot < $GNUPLOT__TMP >> stat_allvar.txt  || echo "Prob with this plot..why?!"
#        #rm -v $GNUPLOT__TMP
#        #rm -v $_FILE_DIFFOUT
#       
#        else
#          echo "ERROR: Mydiag input files NOT found...Why?!"
#          echo $_FILE_1 $MYDIAG_FILE_2
#        fi
# 
#     #fi
#    IDX_=$(( $IDX_MYDIAG + 1 ))
#    done
#    
# elif [[ $_FLAG == 2 ]]; then
#    echo "Mydiag analysis with 2 datasets.."
#
#    IDX_=0
#    for _FIELD in ${MYDIAG_SHORT_NAMES[@]}; do
#      #if [[ $IDX_ != 2 ]] && [[ $IDX_MYDIAG != 5 ]] && [[ $IDX_MYDIAG != 8 ]] && [[ $IDX_MYDIAG != 11 ]] && [[ $IDX_MYDIAG != 14 ]] && [[ $IDX_MYDIAG != 25 ]] && [[ $IDX_MYDIAG != 33 ]] && [[ $IDX_MYDIAG != 35 ]]; then
#        echo "$IDX_ ) I am working on ${MYDIAG_SHORT_NAMES[${IDX_MYDIAG}]}.."
#
#        # Infiles
#        _FILE_1="${MYDIAG_PATH_1}/${MYDIAG_FILES[${IDX_MYDIAG}]}.nc"
#        _FILE_2="${MYDIAG_PATH_2}/${MYDIAG_FILES[${IDX_MYDIAG}]}.nc"
#        _FILE_3="${MYDIAG_PATH_3}/${MYDIAG_FILES[${IDX_MYDIAG}]}.nc"
#        #     
#        if [[ -f $_FILE_1 ]] && [[ -f $MYDIAG_FILE_2 ]] && [[ -f $MYDIAG_FILE_3 ]] ; then
#
#          # Select dates 
#          cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $_FILE_1 seldate1.nc
#          cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $_FILE_2 seldate2.nc
#          cdo seldate,${ANA_STARTDATE:0:4}-${ANA_STARTDATE:4:2}-${ANA_STARTDATE:6:2}T00:00:00,${ANA_ENDDATE:0:4}-${ANA_ENDDATE:4:2}-${ANA_ENDDATE:6:2}T23:30:00 $_FILE_3 seldate3.nc
#
#          # Compute the differences 
#          _DIFFOUT_1="Diff_1_${MYDIAG_FIELD}.nc"
#          #cdo sub ${_FILE_1} ${MYDIAG_FILE_2} $MYDIAG_DIFFOUT_1
#          cdo sub seldate1.nc seldate2.nc $_DIFFOUT_1
#          _DIFFOUT_2="Diff_2_${MYDIAG_FIELD}.nc"
#          #cdo sub ${_FILE_3} ${MYDIAG_FILE_2} $MYDIAG_DIFFOUT_2
#          cdo sub seldate3.nc seldate2.nc $_DIFFOUT_2
#          _DIFFOUT_M="Diff_M_${MYDIAG_FIELD}.nc"
#          cdo sub seldate3.nc seldate1.nc $_DIFFOUT_M
#
#          # Extract TS
#          _PLOTINFILE_1="plotinfile_1_${MYDIAG_FIELD}.txt"
#          _PLOTINFILE_2="plotinfile_2_${MYDIAG_FIELD}.txt"
#          _PLOTINFILE_3="plotinfile_3_${MYDIAG_FIELD}.txt"
#          _PLOTINFILE_DIFF_1="plotinfile_diff_1_${MYDIAG_FIELD}.txt"
#          _PLOTINFILE_DIFF_2="plotinfile_diff_2_${MYDIAG_FIELD}.txt"
#          _PLOTINFILE_DIFF_M="plotinfile_diff_M_${MYDIAG_FIELD}.txt"
#
#          # The following two line should be RM 
#          #cdo outputtab,date,time,value,name $_FILE_1 | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_1
#          #cdo outputtab,date,time,value,name $_FILE_2 | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_2
#          #cdo outputtab,date,time,value,name $_FILE_3 | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_3
#
#          cdo outputtab,date,time,value,name seldate1.nc | grep "$_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_1
#          cdo outputtab,date,time,value,name seldate2.nc | grep "$_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_2
#          cdo outputtab,date,time,value,name seldate3.nc | grep "$_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_3
#
#          cdo outputtab,date,time,value,name $_DIFFOUT_1 | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_DIFF_1
#          cdo outputtab,date,time,value,name $_DIFFOUT_2 | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_DIFF_2
#          cdo outputtab,date,time,value,name $_DIFFOUT_M | grep "$MYDIAG_FIELD" | grep -v "1e+20" > $MYDIAG_PLOTINFILE_DIFF_M
#                    
#
#          #ls seldate?.nc
#          rm -v seldate1.nc
#          rm -v seldate2.nc
#          rm -v seldate3.nc
#
#
#          # Plot TS and Diff
#          PLOT_SDATE=$ANA_STARTDATE
#          #PLOT_SDATE=$( date -d "${ANA_STARTDATE:0:8} 2 day" +%Y%m%d )
#          PLOT_EDATE=$ANA_ENDDATE
#
#          _PLOTUDM=${MYDIAG_UDM[${IDX_MYDIAG}]}
#
#          _PLOT=$( echo "$MYDIAG_PLOT_TPL" | sed -e "s/%FIELD%/${MYDIAG_FILES[${IDX_MYDIAG}]}/g"  -e "s/%DATES%/"${PLOT_SDATE}_${PLOT_EDATE}"/g" )
#          echo "_PLOT_TPL $MYDIAG_PLOT"
#
#          GNUPLOT__TMP="mydiag_tmp.gpl_${MYDIAG_FILES[${IDX_MYDIAG}]}"
#          echo "#" > ${GNUPLOT__TMP}
#          #echo "set term jpeg size 1600,1000 giant" >> ${GNUPLOT__TMP}
#          echo "set term jpeg size 1000,800 giant" >> ${GNUPLOT__TMP}
#          echo "set output \"$_PLOT\" " >> ${GNUPLOT_MYDIAG_TMP}
#
#          echo "stats '$_PLOTINFILE_1' using 3 name 'STATS1' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#          echo "stats '$_PLOTINFILE_2' using 3 name 'STATS2' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#          echo "stats '$_PLOTINFILE_3' using 3 name 'STATS3' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#          echo "stats '$_PLOTINFILE_DIFF_1' using 3 name 'STATSD1' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#          echo "stats '$_PLOTINFILE_DIFF_2' using 3 name 'STATSD2' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#          echo "stats '$_PLOTINFILE_DIFF_M' using 3 name 'STATSDM' nooutput" >> ${GNUPLOT_MYDIAG_TMP}
#
#          echo "set multiplot layout 3,1 title \"Time Series ( VAR: ${_LONG_NAMES[${IDX_MYDIAG}]}  DT: $ANA_STARTDATE - $ANA_ENDDATE )\" " >> ${GNUPLOT_MYDIAG_TMP}
#          #echo "set title \"Time Series ( VAR: ${_LONG_NAMES[${IDX_MYDIAG}]}  DT: $ANA_STARTDATE - $ANA_ENDDATE )\" " >> ${GNUPLOT_MYDIAG_TMP}
#          
#          echo "set xlabel \"Time\" " >> ${GNUPLOT__TMP}
#          echo "set xdata time " >> ${GNUPLOT__TMP}
#          echo "set timefmt \"%Y-%m-%d %H:%M:%S\" " >> ${GNUPLOT__TMP}
#          echo "set xrange [\"${PLOT_SDATE:0:4}-${PLOT_SDATE:4:2}-${PLOT_SDATE:6:2} 00:00:00\":\"${PLOT_EDATE:0:4}-${PLOT_EDATE:4:2}-${PLOT_EDATE:6:2} 23:30:00\"] " >> ${GNUPLOT__TMP}
#          echo "set format x \"%d/%m/%Y\" " >> ${GNUPLOT__TMP}
#          echo "set ylabel \"${_FIELD} ${MYDIAG_PLOTUDM}\" " >> ${GNUPLOT_MYDIAG_TMP}
#          echo "set grid " >> ${GNUPLOT__TMP}
#          echo "set xzeroaxis lw 2" >> ${GNUPLOT__TMP}
#          #echo "set key outside" >> ${GNUPLOT__TMP}
#
#          echo "plot '$_PLOTINFILE_3' using 1:3 with line lw 2 lt rgb \"red\" title gprintf(\"${MYDIAG_INTAG_3} (AVG = %g ${MYDIAG_PLOTUDM} ) \", STATS3_mean), '$MYDIAG_PLOTINFILE_1' using 1:3 with line lw 2 lt rgb \"orange\" title gprintf(\"${MYDIAG_INTAG_1} (AVG = %g ${MYDIAG_PLOTUDM} ) \", STATS1_mean), '$MYDIAG_PLOTINFILE_2' using 1:3 with line lw 2 lt rgb \"blue\" title gprintf(\"${MYDIAG_INTAG_2} (AVG = %g ${MYDIAG_PLOTUDM} )\", STATS2_mean) " >> ${GNUPLOT_MYDIAG_TMP}
#          # SSH:
#          #echo "plot '$_PLOTINFILE_3' using 1:3 with line lw 2 lt rgb \"dark-green\" title gprintf(\"${MYDIAG_INTAG_3} (AVG = %g ${MYDIAG_PLOTUDM} ) \", STATS3_mean), '$MYDIAG_PLOTINFILE_1' using 1:3 with line lw 2 lt rgb \"red\" title gprintf(\"${MYDIAG_INTAG_1} (AVG = %g ${MYDIAG_PLOTUDM} ) \", STATS1_mean), '$MYDIAG_PLOTINFILE_2' using 1:3 with line lw 2 lt rgb \"black\" title gprintf(\"${MYDIAG_INTAG_2} (AVG = %g ${MYDIAG_PLOTUDM} )\", STATS2_mean) " >> ${GNUPLOT_MYDIAG_TMP}
#          ##echo "plot '$_PLOTINFILE_DIFF_1' using 1:3 with line lw 2 lt rgb \"black\" title \"Diff: ${MYDIAG_INTAG_1} - ${MYDIAG_INTAG_2}\",'$MYDIAG_PLOTINFILE_DIFF_2' using 1:3 with line lw 2 lt rgb \"green\" title \"Diff: ${MYDIAG_INTAG_3} - ${MYDIAG_INTAG_2}\" " >> ${GNUPLOT_MYDIAG_TMP}
#          echo "plot '$_PLOTINFILE_DIFF_1' using 1:3 with line lw 2 lt rgb \"orange\" title \"Diff: ${MYDIAG_INTAG_1} - ${MYDIAG_INTAG_2}\",'$MYDIAG_PLOTINFILE_DIFF_2' using 1:3 with line lw 2 lt rgb \"red\" title \"Diff: ${MYDIAG_INTAG_3} - ${MYDIAG_INTAG_2}\"" >> ${GNUPLOT_MYDIAG_TMP}
#          echo "plot '$_PLOTINFILE_DIFF_M' using 1:3 with line lw 2 lt rgb \"dark-green\" title \"Diff: ${MYDIAG_INTAG_3} - ${MYDIAG_INTAG_1}\"" >> ${GNUPLOT_MYDIAG_TMP}
#          # OLD with mean diff and quartiles:
#          #echo "plot '$_PLOTINFILE_DIFF_1' using 1:3 with line lw 2 lt rgb \"orange\" title \"Diff: ${MYDIAG_INTAG_1} - ${MYDIAG_INTAG_2}\",'$MYDIAG_PLOTINFILE_DIFF_2' using 1:3 with line lw 2 lt rgb \"red\" title \"Diff: ${MYDIAG_INTAG_3} - ${MYDIAG_INTAG_2}\", STATSD1_mean lw 2 lc rgb \"black\" title gprintf(\"${MYDIAG_INTAG_1}-${MYDIAG_INTAG_2} mean %g ${MYDIAG_PLOTUDM} \", STATSD1_mean) , STATSD1_lo_quartile lw 2 lc rgb \"orange\" title \"${MYDIAG_INTAG_1}-${MYDIAG_INTAG_2} 1st quartile\",STATSD1_up_quartile lw 2 lc rgb \"orange\" title \"${MYDIAG_INTAG_1}-${MYDIAG_INTAG_2} 3rd quartile\",STATSD2_mean lw 2 lc rgb \"blue\" title gprintf( \"${MYDIAG_INTAG_3}-${MYDIAG_INTAG_2} mean = %g ${MYDIAG_PLOTUDM} \", STATSD2_mean ), STATSD2_lo_quartile lw 2 lc rgb \"red\" title \"${MYDIAG_INTAG_3}-${MYDIAG_INTAG_2} 1st quartile\",STATSD2_up_quartile lw 2 lc rgb \"red\" title \"${MYDIAG_INTAG_3}-${MYDIAG_INTAG_2} 3rd quartile\"  " >> ${GNUPLOT_MYDIAG_TMP}
#         #echo "plot '$_PLOTINFILE_DIFF_M' using 1:3 with points pt 1 ps 1 lt rgb \"dark-green\" title \"Diff: ${MYDIAG_INTAG_3} - ${MYDIAG_INTAG_1}\",STATSDM_mean lw 2 lc rgb \"black\" title gprintf( \"${MYDIAG_INTAG_3}-${MYDIAG_INTAG_1} mean = %g ${MYDIAG_PLOTUDM} \", STATSDM_mean ), STATSDM_lo_quartile lw 2 lc rgb \"green\" title \"${MYDIAG_INTAG_3}-${MYDIAG_INTAG_1} 1st quartile\",STATSDM_up_quartile lw 2 lc rgb \"green\" title \"${MYDIAG_INTAG_3}-${MYDIAG_INTAG_1} 3rd quartile\" " >> ${GNUPLOT_MYDIAG_TMP}
#
#        # Plot
#        gnuplot < $GNUPLOT__TMP || echo "Prob with this plot..why?!"
#        #rm -v $GNUPLOT__TMP
#        #rm -v $_FILE_DIFFOUT
#
#        else
#          echo "ERROR: Mydiag input files NOT found...Why?!"
#          echo $_FILE_1 $MYDIAG_FILE_2 $MYDIAG_FILE_3
#        fi
#
#     #fi
#    IDX_=$(( $IDX_MYDIAG + 1 ))
#    done
#
# fi
#
# echo "WORKDIR: $ANA_WORKDIR"
#
####################### POSTPROC ###########################
#
## Output check
#
## Archive
#
#
