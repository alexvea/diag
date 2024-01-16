#!/usr/bin/env bash
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

function download_list {
        curl -s https://raw.githubusercontent.com/alexvea/diag/main/sql/check_list
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
        esac
}

function display_check_nok {
        echo -e "${RED} [ERROR] ${NC} $1 - More infos : $2" 
}
for test in `download_list`; do
        to_display=0
        TYPE=$(echo $test | awk -F'|' '{ print $1 }')
        DESCRIPTION=$(echo $test | awk -F'|' '{ print $2 }')
        COMMAND=$(echo $test | awk -F'|' '{ print $3 }')
        EXPECTED_RESULT=$(echo $test | awk -F'|' '{ print $4 }')
        OUTPUT_IF_EXPECTED=$(echo $test | awk -F'|' '{ print $5 }')
        case $TYPE in
                "SQL")
                        CURRENT_RESULT=`/usr/bin/env mysql -h$db_host -u$db_user -p$db_passwd -e $COMMAND | grep -E -o "[0-9]+"`
                        EXPECTED_RESULT_TYPE=$(echo $EXPECTED_RESULT  | awk -F';' '{ print $1 }')
                        EXPECTED_RESULT_VALUE=$([[ "${EXPECTED_RESULT_TYPE}" == "cmd" ]] && echo $EXPECTED_RESULT  | awk -F';' '{ print $2 }' | bash || echo $EXPECTED_RESULT | awk -F';' '{ print $2 }')
                        EXPECTED_RESULT_SIGN=$(echo $EXPECTED_RESULT  | awk -F';' '{ print $3 }')
                        test_value $CURRENT_RESULT $EXPECTED_RESULT_VALUE $EXPECTED_RESULT_SIGN && display_check_nok $DESCRIPTION $OUTPUT_IF_EXPECTED
                        #test_value $CURRENT_RESULT $EXPECTED_RESULT_VALUE $EXPECTED_RESULT_SIGN || display_check_nok $DESCRIPTION $OUTPUT_IF_EXPECTED
                ;;


                "FILE")

                ;;
        esac
done