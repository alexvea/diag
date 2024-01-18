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
* 4 types of output : OK, INFO, ERROR, DEBUG.

  1. OK when the expected test is matched. Only display the test description.
  2. INFO when the expected test is not matched with tag info. Display the test description and more info output.
  3. ERROR when the expected test is not matched with tag error. Display the test description and more info output.
  4. DEBUG when -d option is used. Add a line with the test command.
 

 Example :
 ![image](https://github.com/alexvea/diag/assets/35368807/726d4978-ba46-44d5-bc5b-2baa0bde74d5)


