#!/bin/ksh
#
#   @(#)$Id: prodverstamp.sh,v 2007.8 2007/08/27 04:11:03 jleffler Exp $
#
#   $Product: IBM Informix Database Driver for Perl DBI Version 2007.0903 (2007-09-03) $
#
#   Product version stamping tool
#
#   (C) Copyright 2003,2007 JLSS

# Ensure we do not pick up stray environment variables!
BASEVRSN=
PRODDATE=
PRODNAME=
PRODCODE=
LICENCE=
JDCFILE=
CM_DIRS=

Cflag=no        # Print product codename [aka filename prefix]
Dflag=no        # Print date
Fflag=no        # Final build (no _date)
Lflag=no        # Print licence name
Mflag=no        # Print list of CM directories to back up
Nflag=no        # Print product name
Pflag=no        # Print full product version stamp
Vflag=no        # Print version
Aflag=          # Other attribute

# If there is an environment variable...
# This is crucial to the argument-less operation needed in NMD processing.
if [ "X$PRODVERSTAMPFLAGS" != "X" ]
then eval set -- "$@" $PRODVERSTAMPFLAGS
fi

usestr="Usage: $0 [-F][-hCDLMNPV] [-A attribute] -j file.jdc [-c code][-d date][-l licence][-m cmdirs][-n name][-v version] [file ...]"

helpinfo()
{
    echo "$usestr"
    echo "\nCommand options:\n"
    echo "  -A attr Echo the named attribute"
    echo "  -C      Echo the product code (PRODCODE)"
    echo "  -D      Echo the product date (today)"
    echo "  -F      Final release (no date suffix to version number)"
    echo "  -L      Echo the licence string (GNU GPL v2)"
    echo "  -M      Echo the CM directories for the product"
    echo "  -N      Echo the product name (PRODUCT)"
    echo "  -P      Echo the product identifier string (PRODUCT Version VERSION (DATE))"
    echo "  -V      Echo the version number (VERSION.DATE)"
    echo "  -c code Set the product code"
    echo "  -d date Set the product date"
    echo "  -h      Echo this help information"
    echo "  -j file Name of JLSS Distribution Configuration file"
    echo "  -l lic  Set the licence string"
    echo "  -n name Set the product name"
    echo "  -v vrsn Set the version number"
    echo "\nNote that $0 can be used as a pure filter too"
    exit 0
}

while getopts c:d:hj:l:m:n:v:A:CDFLMNPV opt
do
    case $opt in
    c)  PRODCODE="$OPTARG";;
    d)  PRODDATE="$OPTARG";;
    h)  helpinfo;;
    j)  JDCFILE="$OPTARG";;
    l)  LICENCE="$OPTARG";;
    m)  CM_DIRS="$OPTARG";;
    n)  PRODNAME="$OPTARG";;
    v)  BASEVRSN="$OPTARG";;
    A)  Aflag="$OPTARG";;
    C)  Cflag=yes;;
    D)  Dflag=yes;;
    F)  Fflag=yes;;
    L)  Lflag=yes;;
    M)  Mflag=yes;;
    N)  Nflag=yes;;
    P)  Pflag=yes;;
    V)  Vflag=yes;;
    *)  echo "$usestr" 1>&2; exit 1;;
    esac
done
shift `expr $OPTIND - 1`

[ -z "$JDCFILE" ] && { echo "No JDC file specified"; echo "$usestr"; exit 1; }

checkout_file()
{
    file=$1
    [ ! -f $file ] && ${CO:-co} ${COFLAGS:-'-q'} $file
    [ ! -f $file ] && echo "Did not find $file file" 1>&2 && exit 1
}

checkout_file $JDCFILE

# Convert JDC file into a set of shell variable settings
# This is risky - we're executing user-supplied content.
tmp=${TMPDIR:-/tmp}/pvs.$$
trap "rm -f $tmp; exit 1" 1 2 3 13 15
perl -n -e 's/#.*//;
    next unless m/^\s*\w+\s*=/;
    s/\s*=\s*/=/;
    s/\s*$/\n/;
    s/=([^"].*)/="$1"/;
    print;
    ' $JDCFILE > $tmp
. $tmp
rm -f $tmp
trap 1 2 3 13 15

# Arguably, should not evaluate a value until it is demonstrably needed (eg CM_DIRS).
: ${BASEVRSN:="${VERSION:?'VERSION not set in $JDCFILE'}"}
: ${PRODDATE:=`date +%Y-%m-%d`}
: ${PRODNAME:="${NAME:-${PRODNAME:?'NAME not set in $JDCFILE'}}"}
: ${PRODCODE:="${CODE:-${PRODCODE:?'CODE not set in $JDCFILE'}}"}
: ${LICENCE:="GNU General Public Licence Version 2"}
CM_DIRS="$CMDIRECTORIES"
[ -z "$CM_DIRS" ] && CM_DIRS=$([ -d RCS ] && echo RCS; [ -d SCCS ] && echo SCCS;)

# Final build - use base version only
if [ $Fflag = yes ]
then PRODVRSN="${BASEVRSN}"
else PRODVRSN="${BASEVRSN}.`date +%Y%m%d`" # Beware SCCS!
fi

VERSION="$PRODNAME Version $PRODVRSN ($PRODDATE)"

# Display components of version information
[ $Cflag = yes ] && echo "$PRODCODE"
[ $Dflag = yes ] && echo "$PRODDATE"
[ $Lflag = yes ] && echo "$LICENCE"
[ $Mflag = yes ] && echo "$CM_DIRS"
[ $Nflag = yes ] && echo "$PRODNAME"
[ $Pflag = yes ] && echo "$VERSION"
[ $Vflag = yes ] && echo "$PRODVRSN"
[ -n "$Aflag"  ] && { eval echo "\${$Aflag}"; Aflag=yes; }

case "$Cflag$Dflag$Lflag$Mflag$Nflag$Pflag$Vflag$Aflag" in
*yes*)  exit 0;;
esac

# Edit file(s) to set version strings.
# NB: The script below must be immune from change when prodverstamp is
#     run on itself (which is non-trivial to achieve!).
# NB: The $UCPRODCODE line below nominally handles old projects with
#     codes like :RMK: in the files.
# NB: Files (such as this one) may include the RCS-like keyword Product
#     enclosed with dollar signs, and prodverstamp will then expand it.
UCPRODCODE=`echo $PRODCODE | tr '[a-z]' '[A-Z]'`
sed -e 's%[$]Product: [^$]* [$]%$Product: IBM Informix Database Driver for Perl DBI Version 2007.0903 (2007-09-03) $%' \
    -e "s%[$]Product[$]%\$Product: $VERSION \$%" \
    -e "s%[:]PRODNAME:%$PRODNAME%" \
    -e "s%[:]PRODDATE:%$PRODDATE%" \
    -e "s%[:]PRODVRSN:%$PRODVRSN%" \
    -e "s%[:]PRODCODE:%$PRODCODE%" \
    -e "s%[:]$UCPRODCODE:%$VERSION%" \
    -e "s%[:]PRODUCT:%$VERSION%" \
    -e "s%[:]LICENCE:%$LICENCE%" \
    -e "s%[:]VERSION:%$PRODVRSN%" "$@"
