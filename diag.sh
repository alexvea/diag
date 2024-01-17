#!/usr/bin/env bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "The script will help to diagnose somes cases on your Centreon platform."
   echo "Syntax: [-h|d]"
   echo "options:"
   echo "h     Print this help."
   echo "d     Display debug"
   echo
}
conf_path=/etc/centreon/conf.pm
db_user=$(grep mysql_user $conf_path | awk '{ print substr($3,2,length($3) - 3); }')
db_passwd=$(grep mysql_passwd $conf_path | awk '{ print substr($3,2,length($3) - 3); }')
db_host=$(grep mysql_host $conf_path | awk '{ print substr($3,2,length($3) - 3); }' | awk -F":" ' { print $1 } ')
OIFS="$IFS"
IFS=$'\n'

RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

DEBUG=0
#[[ $DEBUG == 1 ]] && set -x
#set +x


function download_list {
        curl -s https://raw.githubusercontent.com/alexvea/diag/main/data/check_list
}

function test_value {
         case $3 in
                "=")
                        [[ $2 == $1 ]] 
                ;;
                "<")
                        [[ $2 -lt $1 ]] 
                ;;
                ">")
                        [[ $2 -gt $1 ]]
                ;;
                "!=")
                        [[ $2 != $1 ]]
                ;;
        esac
return $?
}

function display_check {
        case $1 in
                "nok")
                        echo -e "${RED} [ERROR] ${NC} $2"
                        echo -e "         More infos : $3"
                ;;
                "ok")
                        echo -e "${GREEN} [OK] ${NC} $2"
                ;;
                "debug")
                        echo -e "${BLUE} [DEBUG] ${NC} $2"
                ;;
        esac
}


while getopts "n:arhd" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      d) #display debug
         DEBUG=1
         ;;
     \?) # Invalid option
         exit;;
   esac
done
for test in `download_list`; do
        to_display=0
        TYPE=$(echo $test | awk -F'[|][|]' '{ print $1 }')
        DESCRIPTION=$(echo $test | awk -F'[|][|]' '{ print $2 }')
        COMMAND=$(echo $test | awk -F'[|][|]' '{ print $3 }')
        EXPECTED_RESULT=$(echo $test | awk -F'[|][|]' '{ print $4 }')
        OUTPUT_IF_EXPECTED=$(echo $test | awk -F'[|][|]' '{ print $5 }')
        EXPECTED_RESULT_TYPE=$(echo $EXPECTED_RESULT  | awk -F';;' '{ print $1 }')
        EXPECTED_RESULT_VALUE=$([[ "${EXPECTED_RESULT_TYPE}" == "cmd" ]] && echo $EXPECTED_RESULT  | awk -F';;' '{ print $2 }' | bash || echo $EXPECTED_RESULT | awk -F';;' '{ print $2 }')
        EXPECTED_RESULT_SIGN=$(echo $EXPECTED_RESULT  | awk -F';;' '{ print $3 }')
        case $TYPE in
                "SQL")
                        CURRENT_RESULT=`/usr/bin/env mysql -h$db_host -u$db_user -p$db_passwd -e $COMMAND | grep -E -o "[0-9]+"`
                ;;


                "FILE")

                ;;
                "CMD")
                        CURRENT_RESULT=`echo $COMMAND | bash`
                ;;
        esac

        test_value $CURRENT_RESULT $EXPECTED_RESULT_VALUE $EXPECTED_RESULT_SIGN && display_check ok $DESCRIPTION || display_check nok $DESCRIPTION $OUTPUT_IF_EXPECTED
        [[ $DEBUG == 1 ]] && display_check debug $COMMAND
done
