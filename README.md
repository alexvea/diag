** FOR TESTS ONLY **

Prerequisites :

* Need to have internet to access the github website.
* Only work on Central server (local or deported DB server).

How to use : 
```
 bash <(curl -s https://raw.githubusercontent.com/alexvea/diag/main/diag.sh)
```
Help :
```
The script will help to diagnose somes cases on your Centreon platform.
Syntax: [-h|d]
options:
h     Print this help.
d     Display debug
```

Functionnalities :

* Compatible with SQL request, bash oneliner with characters ||(false condition) and ;;(case).
* Placeholders to get tested and retrieved values on non-expected case output.
* 4 types of output : OK, INFO, DEBUG, ERROR.
