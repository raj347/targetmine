#!/bin/bash
#
# default usage: automine.sh rel
#
# note: you should put the db password in ~/.pgpass if don't
#       want to be prompted for it
#
# sc 09/08
#
# TODO: ant failing and exiting with 0!
#       test full release
#       analyse after stag?
#       if -M -f stops after stag. check
#

# see after argument parsing for all envs related to the release

FTPURL=http://submit.modencode.org/submit/public/list
EXDIRS=/pub/dcc/for_modmine/old   #comma separated, i.e. a,b,c
MODIR=/shared/data/modmine
REPORTS=$MODIR/subs/reports
DATADIR=$MODIR/subs/chado
NEWDIR=$DATADIR/new
WGETDIR=$NEWDIR/wgetdir
PROPDIR=$HOME/.intermine
SCRIPTPATH=../flymine-private/scripts/modmine/

#RECIPIENTS=contrino@flymine.org
RECIPIENTS=contrino@flymine.org,rns@flymine.org
REPORTPATH=file:///shared/data/modmine/subs/reports/

#SOURCES=modmine-static,modencode-metadata,entrez-organism
SOURCES=modmine-static,modencode-metadata
#SOURCES=modencode-metadata

# TODO add check that modmine in path
MINEDIR=$PWD
BUILDDIR=$MINEDIR/integrate/build
#USER=`whoami`


#MINEDIR=$HOME/svn/dev/modmine

# these should not be edited
WEBAPP=y       #defaults: build a webapp
BUILD=y        #          build modmine
CHADOAPPEND=n  #          rebuild the chado db
BUP=n          #          don't do a back up copy of the databases
V=             #          non-verbose mode
#F=;           #          continue stag loading (also after errors)
REL=dev;       #          if no release is passed, do a dev (unless you are validating)
STAG=y         #          run stag loading
TEST=y         #          do acceptance tests
VALIDATING=n   #          not running as a validation (1 entry at a time)
FOUND=n        #          y if new files downloaded
INFILE=undefined #        not using a given list of submissions
TIMESTAMP=`date "+%y%m%d.%H%M"`  # used in the log
NAMESTAMP=undefined     # used to name the acceptance tests
INTERACT=n     #          y: step by step interaction
WGET=y         #          use wget to get files from ftp
VAL1=n         #          y: validate 1! entry
GAM=y          #          y: run get_all_modmine (only in F mode)

INCR=y
FULL=n
META=n         # it builds a new mine with static, organism and metadata only
RESTART=n

progname=$0

function usage () {
	cat <<EOF

Usage: $progname [-F] [-M] [-R] [-V] [-a] [-b] [-e] [-f file_name] [g] [i] [-s] [-t] [-w] [-v] [-x]
	-F: full (modmine) rebuild
	-M: test build (metadata only)
	-R: restart full build after failure
	-V: validation mode: all entries (one at the time)
	-u: validation mode: one entry only
	-a: append to chado
	-b: build a back-up of modchado-$REL
	-e: don't update the sources (don't run get_all_modmine). Valid only in F mode
	-f file_name: using a given list of submissions
	-g: no checking of ftp directory (wget is not run)
	-i: interactive mode
	-s: no new loading of chado (stag is not run)
	-t: no acceptance test run
	-w: no new webapp will be built
	-v: verbode mode
	-x: don't build modmine (!: used for running only tests)

Note: The file is downloaded only if not present or the remote copy
			is newer or has a different size.

examples:

$progname			add new submissions to modmine-dev, getting new files from ftp
$progname -F test		build a modmine-test with metadata, Flybase and Wormbase,
				getting new files from ftp
$progname -M test		build a new chado with all the NEW submissions in
				$FTPURL
				and use this to build a modmine-test
$progname -s -w -t dev	build modmine-dev using the existing modchado-dev,
				without performing acceptance tests and without building the webapp
$progname -f file_name val	build modmine-val using the (already downloaded)
				chadoxml files listed in file_name

EOF
	exit 0
}

while getopts ":FMRVabef:gistuvwx" opt; do
	case $opt in

	F )  echo; echo "Full modMine realease"; FULL=y; BUP=y; INCR=n;;
#   I )  echo; echo "Incremental modMine realease"; INCR=y;;
	M )  echo; echo "Test build (metadata only)"; META=y; INCR=n;;
	R )  echo; echo "Restart full realease"; RESTART=y; FULL=y; INCR=n; STAG=n; WGET=n; BUP=n;;
	V )  echo; echo "Validating all submission (1 by 1)"; VALIDATING=y; META=y; INCR=n; BUP=n; REL=val;;
	u )  echo; echo "Validating 1 submission only"; VALIDATING=y; VAL1=y; META=y; INCR=n; BUP=n; REL=val;;
	a )  echo; echo "Append data in chado" ; CHADOAPPEND=y;;
	b )  echo; echo "Build a back-up of the database." ; BUP=y;;
	e )  echo; echo "don't update all sources (get_all_modmine is not run)" ; GAM=n;;
	f )  echo; INFILE=$OPTARG; WGET=n; echo "Using given list of chadoxml files (wget won't be run):"; more $INFILE;;
	g )  echo; echo "No checking of ftp directory (wget is not run)" ; WGET=n;;
	i )  echo; echo "Interactive mode" ; INTERACT=y;;
	s )  echo; echo "Using previous load of chado (stag is not run)" ; STAG=n; BUP=n; WGET=n;;
	t )  echo; echo "No acceptance test run" ; TEST=n;;
	v )  echo; echo "Verbose mode" ; V=-v;;
	w )  echo; echo "No new webapp will be built" ; WEBAPP=n;;
	x )  echo; echo "modMine will NOT be built" ; BUILD=n; STAG=n; BUP=n; WGET=n;;
	h )  usage ;;
	\?)  usage ;;
	esac
done

shift $(($OPTIND - 1))

if [ -n "$1" ]
then
	if [ $VALIDATING = "y" ]
	then
		REL=val
	else
		REL=$1
	fi
fi


#
# Getting some values from the properties file.
# NOTE: it is assumed that dbhost and dbuser are the same for chado and modmine!!
#     -a to grep also (alleged) binary files
#

DBHOST=`grep -a metadata.datasource.serverName $PROPDIR/modmine.properties.$REL | awk -F "=" '{print $2}'`
DBUSER=`grep -a metadata.datasource.user $PROPDIR/modmine.properties.$REL | awk -F "=" '{print $2}'`
DBPW=`grep -a metadata.datasource.password $PROPDIR/modmine.properties.$REL | awk -F "=" '{print $2}'`
CHADODB=`grep -a metadata.datasource.databaseName $PROPDIR/modmine.properties.$REL | awk -F "=" '{print $2}'`
MINEDB=`grep -a db.production.datasource.databaseName $PROPDIR/modmine.properties.$REL | awk -F "=" '{print $2}'`

LOADLOG="$DATADIR/$USER.$REL-ld.log"

echo
echo "================================="
echo "Building modmine-$REL on $DBHOST."
echo "================================="
echo "Logs: $LOADLOG"
#echo "      $DATADIR/wget.log"
echo
echo "current directory: $MINEDIR"
echo

if [ $VALIDATING = "y" ] && [ $STAG = "n" ] && [ -n "$1" ]
then
	NAMESTAMP="$1"
	echo "NOTE: you are restarting after a failed modMine build: the test result will be named $NAMESTAMP.html"
elif [ $VALIDATING = "y" ] && [ $STAG = "n" ]
then
	echo "NOTE: you have not passed a submission name after restarting a failed modMine build: the test result will be named $TIMESTAMP.html"
	echo
elif [ $VALIDATING = "y" ] && [ $STAG = "y" ] && [ ! -n $1 ]
then
echo OK
# elif [ $VALIDATING = "y" ] && [ $STAG = "y" ] && [ -n $1 ] && [ $1 != "val" ]
# then
#     echo "NOTE: You are validating a submission using ===> $1 <=== mine"
#     echo
fi

if [ $INTERACT = "y" ]
then
echo
echo "Press return to continue.."
echo -n "->"
read
fi

#---------------------------------------
# getting the chadoxml from ftp site
#---------------------------------------

#cd $DATADIR
cd $NEWDIR
# this for confirmation the program run and to avoid to grep on a non-existent file
touch $LOADLOG

#...and get it if the remote timestamp is newer than the local
# it will make a copy of the local (as name.chadoxml.n)

if [ $WGET = "y" ]
then
		echo
		echo "Getting data from $FTPURL. Log in $DATADIR/wget.log"
		echo

# TODO: at the moment timestamp is not working, see mail to eo.
# http server needs to return last modified time to the wget HEAD request, and this is not happening.

		#wget -r -nd -N -P$NEWDIR $FTPURL -A chadoxml  --progress=dot:mega -a wget.log
#		wget -r -nd -X $EXDIRS -N -P$NEWDIR $FTPURL -A chadoxml  --progress=dot:mega 2>&1 | tee -a $DATADIR/wget.log

#		wget -r -nd -l1 -N -P$WGETDIR $FTPURL -R *tracks*,*citation*,*stanzas*,*download*  -k -K --progress=dot:mega 2>&1 | tee -a $DATADIR/wget.log

		wget -r -nd -l1 -N -P$WGETDIR $FTPURL -X download,citation,*stanzas* -A chadoxml --progress=dot:mega 2>&1 | tee -a $DATADIR/wget.log

#		wget -r -nd -N -P$WGETDIR $FTPURL -I extracted -X download,citation,*stanzas* -A chadoxml -k --progress=dot:mega 2>&1 | tee -a $DATADIR/wget.log

		#r recursive
		#nd the directories structure is NOT recreated locally
		#-l 2 depth of recursion
		#np no parents: only files below a certain directory are retrieved
		#P destination dir
		#a append to log
		#-X list of directories to exclude
    #-N timestamping
		echo $TIMESTAMP

		#---------------------------------------
		# check if any new file, exit if not
		#---------------------------------------

		cd $NEWDIR

		for sub in *.chadoxml
		do
			if [ ! -L $sub ] #is not a symbolic link
			then
				FOUND=y
				break
			fi
		done

		if [ "$FOUND" = "n" ]
		then
			echo
			echo "no new data found on ftp. exiting."
			echo

			exit 0;
		fi

if [ $INTERACT = "y" ]
then
		echo "press return to continue.."
		read
fi

fi #if $WGET=y

#---------------------------------------
# build the chado db
#---------------------------------------
#
cd $DATADIR

# do a back-up?
if [ "$BUP" = "y" ]
then
dropdb -e "$CHADODB"-old -h $DBHOST -U $DBUSER;
createdb -e "$CHADODB"-old -T $CHADODB -h $DBHOST -U $DBUSER\
|| { printf "%b" "\nMine building FAILED. Please check previous error message.\n\n" ; exit 1 ; }
fi

# build new?
 if [ "$CHADOAPPEND" = "n" ] && [ "$STAG" = "y" ] && [ "$VALIDATING" = "n" ]
 then
 # rebuild skeleton chado db
 	dropdb -e $CHADODB -h $DBHOST -U $DBUSER;
 	createdb -e $CHADODB -h $DBHOST -U $DBUSER || { printf "%b" "\nMine building FAILED. Please check previous error message.\n\n" ; exit 1 ; }
 
 	psql -d $CHADODB -h $DBHOST -U $DBUSER < $MODIR/build_empty_chado.sql\
 	|| { printf "%b" "\nMine building FAILED. Please check previous error message.\n\n" ; exit 1 ; }
 
 if [ $INTERACT = "y" ]
 then
 echo "press return to continue.."
 read
 fi
 
 fi

#---------------------------------------
# fill chado db
#---------------------------------------

if [ $STAG = "y" ]
then

cd $NEWDIR

LOOPVAR="*.chadoxml"

	# TODO : check newdir issues when wget source is stable
	if [ ! $INFILE = "undefined" ]
	then
    LOOPVAR=`cat $INFILE`
	fi


#for sub in *.chadoxml
for sub in $LOOPVAR
do
if [ -L $sub ] #is a symbolic link
then
continue
fi

echo "================"
echo "$sub..."
echo "================"

#
# for validation, we rebuild chado for each file
#
if [ "$CHADOAPPEND" = "n" ] && [ "$VALIDATING" = "y" ]
then
cd $DATADIR
# rebuild skeleton chado db
	dropdb -e $CHADODB -h $DBHOST -U $DBUSER;
	createdb -e $CHADODB -h $DBHOST -U $DBUSER || { printf "%b" "\nMine building FAILED. Please check previous error message.\n\n" ; exit 1 ; }

	psql -d $CHADODB -h $DBHOST -U $DBUSER < $MODIR/build_empty_chado.sql\
	|| { printf "%b" "\nMine building FAILED. Please check previous error message.\n\n" ; exit 1 ; }
cd $NEWDIR
fi


echo
echo "filling $CHADODB db with $sub..."
echo "`date "+%y%m%d.%H%M"` $sub" >> $LOADLOG

DCCID=`echo $sub | cut -f 1 -d.`

#echo $DCCID

stag-storenode.pl -D "Pg:$CHADODB@$DBHOST" -user $DBUSER -password \
$DBPW -noupdate cvterm,dbxref,db,cv,feature $sub \
|| { printf "\n **** $sub **** stag-storenode FAILED at `date`.\n" "%b" \
>> `date "+%y%m%d.$REL.log"`; grep -v $sub $LOADLOG > tmp ; mv -f tmp $LOADLOG; exit 1 ; }

psql -h $DBHOST -d $CHADODB -U $DBUSER -c "insert into experiment_prop (experiment_id, name, value, type_id) select max(experiment_id), 'dcc_id', '$DCCID', 1292 from experiment_prop;"

#if we are not validating we move away the file
if [ $VALIDATING = "n" ]
then
mv $sub $DATADIR
ln -s ../$sub $sub
fi

#if we are validating, we'll process an entry at a time
if [ $VALIDATING = "y" ]
then
# to name the acceptance tests file
NAMESTAMP=`echo $sub | awk -F "." '{print $1}'`
echo "******"
echo $NAMESTAMP
echo "******"

cd $MINEDIR
echo "Building modMine $REL"
echo
# new build. static, metadata
../bio/scripts/project_build -a $SOURCES -V $REL $V -b -t localhost /tmp/mod-meta\
|| { printf "%b" "\n modMine build FAILED.\n" ; exit 1 ; }


echo
echo "running acceptance tests"
echo
cd $MINEDIR/integrate
ant $V -Drelease=$REL acceptance-tests-metadata|| { printf "%b" "\n acceptance test FAILED.\n" ; exit 1 ; }

if [ $NAMESTAMP != "undefined" ]
then
TIMESTAMP="$NAMESTAMP"
fi

# check chado for new features
cd $MINEDIR

# this is done because there is a problem with automount....
ls $REPORTS > /dev/null

$SCRIPTPATH/add_chado_feats_to_report.pl $DBHOST $CHADODB $DBUSER $BUILDDIR/acceptance_test.html > $REPORTS/$TIMESTAMP.html

echo "sending mail!!"
mail $RECIPIENTS -s "$TIMESTAMP report, also in $REPORTPATH/$TIMESTAMP.html" < $REPORTS/$TIMESTAMP.html

echo
echo "acceptance test results in "
echo "$REPORTS/$TIMESTAMP.html"
echo


if [ "$VAL1" = "y" ]
then
break;
fi

fi #VAL=y

#go back to the chado directory
cd $NEWDIR
done
exit;

else
echo
echo "Using previously loaded chado."
echo
if [ $INTERACT = "y" ]
then
echo "press return to continue.."
read
fi

fi # if $STAG=y


#---------------------------------------
# build modmine
#---------------------------------------
#if [ $BUILD = "y" ] && [ $VALIDATING = "n" ]
if [ $BUILD = "y" ]
then
cd $MINEDIR

echo "Building modMine $REL"
echo

if [ $INCR = "y" ]
then
# just add to present mine
# NB: if failing won't stop!! ant exit with 0!
echo; echo "Appending new chado (metadata) to modmine-$REL.."
cd integrate
ant -v -Drelease=$REL -Dsource=modencode-metadata || { printf "%b" "\n modMine build FAILED.\n" ; exit 1 ; }
elif [ $RESTART = "y" ]
then
# restart build after failure
echo; echo "Restating build.."
../bio/scripts/project_build -V $REL $V -l -t localhost /tmp/mod-all\
|| { printf "%b" "\n modMine build FAILED.\n" ; exit 1 ; }
elif [ $META = "y" ]
then
# new build. static, metadata, organism
../bio/scripts/project_build -a $SOURCES -V $REL $V -b -t localhost /tmp/mod-meta\
|| { printf "%b" "\n modMine build FAILED.\n" ; exit 1 ; }
else
# new build, all the sources
# get the most up to date sources ..
if [ $GAM = "y" ]
then
../bio/scripts/get_all_modmine.sh\
|| { printf "%b" "\n modMine build FAILED.\n" ; exit 1 ; }
fi
# .. and build modmine
../bio/scripts/project_build -V $REL $V -b -t localhost /tmp/mod-all\
|| { printf "%b" "\n modMine build FAILED.\n" ; exit 1 ; }
fi


else
echo
echo "Using previously built modMine."
echo
fi #BUILD=y

if [ $INTERACT = "y" ]
then
echo
echo "press return to continue.."
read
fi

#---------------------------------------
# building webapp
#---------------------------------------
if [ "$WEBAPP" = "y" ]
then
cd $MINEDIR/webapp
ant -Drelease=$REL $V default remove-webapp release-webapp
fi

if [ $INTERACT = "y" ]
then
echo
echo "press return to continue.."
read
fi

#---------------------------------------
# and run acceptance tests
#---------------------------------------
#if [ "$TEST" = "y" ] && [ $VALIDATING = "n" ]
if [ "$TEST" = "y" ]
then
echo
echo "========================"
echo "running acceptance tests"
echo "========================"
echo
cd $MINEDIR/integrate

if [ $FULL = "y" ]
then
ant $V -Drelease=$REL acceptance-tests
else
ant $V -Drelease=$REL acceptance-tests-metadata
fi

if [ $NAMESTAMP != "undefined" ]
then
TIMESTAMP="$NAMESTAMP"
fi

# check chado for new features
cd $MINEDIR
$SCRIPTPATH/add_chado_feats_to_report.pl $DBHOST $CHADODB $DBUSER $BUILDDIR/acceptance_test.html > $REPORTS/$TIMESTAMP.html

echo "sending mail!!"
mail $RECIPIENTS -s "$TIMESTAMP report, also in $REPORTPATH/$TIMESTAMP.html" < $REPORTS/$TIMESTAMP.html

#elinks $REPORTS/$TIMESTAMP.html

echo
echo "acceptance test results in "
echo "$REPORTS/$TIMESTAMP.html"
echo
fi

