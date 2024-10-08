#!/usr/bin/env bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "The script will help to diagnose somes cases on your Centreon platform."
   echo "Syntax: [-h|-c PATH_TO_CHECK_LIST|-d]"
   echo "options:"
   echo "-h     Print this help."
   echo "-c     Use local check_list."
   echo "      ie: -c PATH_TO_CHECK_LIST"
   echo "-d     Display debug."
   echo
}
conf_path=/etc/centreon/conf.pm
if [ ! -f "$conf_path" ]; then
        echo "The file $conf_path doesn't exist. Are you on a Central server ?"
        exit
fi
db_user=$(grep mysql_user $conf_path | awk '{ print substr($3,2,length($3) - 3); }')
db_passwd=$(grep mysql_passwd $conf_path | awk '{ print substr($3,2,length($3) - 3); }')
db_host=$(grep mysql_host $conf_path | awk '{ print substr($3,2,length($3) - 3); }' | awk -F":" ' { print $1 } ')

OIFS="$IFS"
IFS=$'\n'
RED=$'\033[0;31m'
NC=$'\033[0m' # No Color
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
PURPLE=$'\033[0;35m'
AWK_LINE_DELIM='[|][|][|]'
AWK_EXPECT_DELIM=';;;'

DEBUG=0
#[[ $DEBUG == 1 ]] && set -x
#set +x

function curl_download_list {
        /usr/bin/env curl -s $1
}

function test_value {
#$1 $CURRENT_RESULT
#$2 $EXPECTED_RESULT_VALUE 
#$3 $EXPECTED_RESULT_SIGN 
#$4 $EXPECTED_RESULT_DISPLAY_TYPE 
#$5 $DESCRIPTION
#$6 $OUTPUT_IF_EXPECTED
         case $3 in
                "=")
                        [[ $1 == $2 ]] 
                ;;
                "<")
                        [[ $1 -lt $2 ]] 
                ;;
                ">")
                        [[ $1 -gt $2 ]]
                ;;
                "!=")
                        [[ $1 != $2 ]]
                ;;
                "regex")
                        [[ $1 =~ $2 ]]
                ;;
        esac
[[ $? -eq 0 ]] && display_check ok $5 || display_check $4 $5 `echo $6 | sed "s/RESULT_VALUE/${YELLOW}$1${NC}/" | sed "s/EXPECTED_VALUE/${PURPLE}$2${NC}/g"`
}

function display_check {
        case $1 in
                "error")
                        echo -e "${RED} [ERROR] ${NC} $2"
                        echo -e "               More infos : $3"
                ;;
                "ok")
                        echo -e "${GREEN}   [OK]  ${NC} $2"
                ;;
                "debug")
                        echo -e "       [DEBUG] ${NC} $2"
                ;;
                "info")
                        echo -e "${BLUE} [INFO]  ${NC} $2"
                        echo -e "               More infos : $3"
                ;;
        esac
}

function validate_line {
        column_nb=5
        first_field_regex='^(CMD|SQL)'
        forth_field_regex='^(value|cmd);;;.*;;;(=|>|<|!=|regex);;;(info|error)'
        five_field_regex='^$'
        awk -v AWK_LINE_DELIM="${AWK_LINE_DELIM}" -v column_nb="$column_nb" -v first_field_regex="$first_field_regex" -v forth_field_regex="$forth_field_regex" -v five_field_regex="$five_field_regex" -v err=0 'BEGIN{FS=OFS=AWK_LINE_DELIM} NF!=column_nb{print " Incorrect number of fields in this test : need " column_nb; err = 1;exit err}
        !($1~first_field_regex) {print " 1st field invalid, should be "first_field_regex; err = 1}
        !($4~forth_field_regex) {print " 4th field invalid, should be "forth_field_regex; err = 1}
        ($5~five_field_regex) {print " 5th field invalid, should not be "five_field_regex; err = 1}
        !(true) {exit err}' <<< $1
}

while getopts "hdc:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      d) #display debug
         DEBUG=1
         ;;

      c) #Use localcheck_file
         [[ ! -f $OPTARG ]] && echo "The specified local check_file doesn't exist." && exit || CHECK_LIST_PATH=$OPTARG
         ;;
     \?) # Invalid option
         exit;;
   esac
done
[[ -f $CHECK_LIST_PATH ]] && CURL_URL=file:///$CHECK_LIST_PATH || CURL_URL=https://raw.githubusercontent.com/alexvea/diag/main/data/check_list
echo "### Using check_list : $CURL_URL ###"
download_list=`curl_download_list $CURL_URL`
nb_line=`echo "$download_list" | wc -l`
x=0
for test in $download_list; do
        ((x++))
        [[ $x -lt 10 ]] && space=" " || space=""; echo -ne "$space$x/$nb_line "
        validate_line $test || continue
        TYPE=$(echo $test | awk -F${AWK_LINE_DELIM} '{ print $1 }')
        DESCRIPTION=$(echo $test | awk -F${AWK_LINE_DELIM} '{ print $2 }')
        COMMAND=$(echo $test | awk -F${AWK_LINE_DELIM} '{ print $3 }')
        EXPECTED_RESULT=$(echo $test | awk -F${AWK_LINE_DELIM} '{ print $4 }')
        OUTPUT_IF_EXPECTED=$(echo $test | awk -F${AWK_LINE_DELIM} '{ print $5 }')
        EXPECTED_RESULT_TYPE=$(echo $EXPECTED_RESULT  | awk -F${AWK_EXPECT_DELIM} '{ print $1 }')
        EXPECTED_RESULT_VALUE=$([[ "${EXPECTED_RESULT_TYPE}" == "cmd" ]] && echo $EXPECTED_RESULT  | awk -F${AWK_EXPECT_DELIM} '{ print $2 }' | bash || echo $EXPECTED_RESULT | awk -F${AWK_EXPECT_DELIM} '{ print $2 }')
        EXPECTED_RESULT_SIGN=$(echo $EXPECTED_RESULT  | awk -F${AWK_EXPECT_DELIM} '{ print $3 }')
        EXPECTED_RESULT_DISPLAY_TYPE=$(echo $EXPECTED_RESULT  | awk -F${AWK_EXPECT_DELIM} '{ print $4 }')
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
        [ -z "$CURRENT_RESULT" ] && CURRENT_RESULT="NULL"
        test_value $CURRENT_RESULT $EXPECTED_RESULT_VALUE $EXPECTED_RESULT_SIGN $EXPECTED_RESULT_DISPLAY_TYPE $DESCRIPTION $OUTPUT_IF_EXPECTED
        [[ $DEBUG == 1 ]] && display_check debug $COMMAND
done
