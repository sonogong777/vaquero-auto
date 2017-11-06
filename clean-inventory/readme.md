# clean inventory script. 
  Based on auto-inventory script with preinstall steps disabled for inventory.yml file generation.
  Attempting to automate Cisco COS deployemnt 

Currently implemented steps..
1.	Validates csv file for field counts and brief logic check. Example, if ipmi field exist then check for two interface configuration etc.
2.	Check for existing entry/duplicates in the inventory file an remove them if identified.  This is a confirmed test that we can remove a configuration block form inventory file.
3.	Update inventory files with configuration.  (cos3260,cos465,cmc)
4.      Log files generated on simultaneous execution.  pre."hostname".log.


<H3> Usage </H3>

```bash
  ./clean-inventory  
  Usage: ./clean-inventory.sh <csv file name>
  example: ./clean-inventory.sh test.csv.sh
  csv file format: host mac mgmt_ip user password ipmi int1 int2 cimc sioc bmc subnet workflow

  output file: inventory.yml in CWD
````

<a href="https://wwwin-github.cisco.com/kerhee/vaquero-auto/blob/master/clean-inventory/inventory.yml"> To view updated inventory.yml, click here </a>



Sample Execution:

```diff
./clean-inventory.sh full.csv
+ Validating full.csv field counts
+ Quick test on full.csv logical fields
+ cde465-02, removing inventory configuration
+ Removing cde465-02 configuration from inventory.yml
+ cos3260-01, removing inventory configuration
+ Removing cos3260-01 configuration from inventory.yml
+ cde465-01, removing inventory configuration
+ Removing cde465-01 configuration from inventory.yml
+ cos3260-02, removing inventory configuration
+ Removing cos3260-02 configuration from inventory.yml
+ cde465-03, removing inventory configuration
+ Removing cde465-03 configuration from inventory.yml
+ cos3260-03, removing inventory configuration
+ Removing cos3260-03 configuration from inventory.yml
+ cde465-04, removing inventory configuration
+ Removing cde465-04 configuration from inventory.yml
+ cos3260-04, removing inventory configuration
+ Removing cos3260-04 configuration from inventory.yml
+ cde465-05, removing inventory configuration
+ Removing cde465-05 configuration from inventory.yml
+ cos3260-05, removing inventory configuration
+ Removing cos3260-05 configuration from inventory.yml
+ cde465-06, removing inventory configuration
+ Removing cde465-06 configuration from inventory.yml
+ cos3260-06, removing inventory configuration
+ Removing cos3260-06 configuration from inventory.yml
+ cmc-01, removing inventory configuration
+ Removing cmc-01 configuration from inventory.yml
```

Input file format: 
Sample csv file full.csv
```bash
host, mac, mgmt_ip, user, password, ipmi, int1, int2, cimc, sioc, bmc, subnet, workflow
cde465-02,0c:c4:7a:bb:0d:2a,1.1.1.1,ADMIN,ADMIN,1.1.1.1,2.2.2.2,3.3.3.3,,,,3260-subnet,cos465-wf
cos3260-01,90:e2:ba:e6:96:78,67.178.3.5,admin,Comcast!23,,67.178.10.116,67.178.10.117,67.178.30.38,67.178.30.35,67.178.30.36,3260-subnet,cos3260-wf
cde465-01,0c:c4:7a:bb:0d:2a,67.178.3.9,ADMIN,ADMIN,67.178.5.142,67.178.10.124,67.178.10.125,,,,3260-subnet,cos465-wf
cos3260-02,90:e2:ba:e6:96:d8,67.178.3.6,admin,Comcast!23,,67.178.10.118,3.3.3.3,67.178.30.138,67.178.30.35,67.178.30.36,3260-subnet,cos3260-wf
cde465-03,0c:c4:7a:bb:0d:2a,1.1.1.1,ADMIN,ADMIN,1.1.1.1,2.2.2.2,1.1.1.1,,,,3260-subnet,cos465-wf
cos3260-03,90:e2:ba:e6:97:14,67.178.3.7,admin,Comcast!23,,67.178.10.120,67.178.10.121,67.178.30.38,67.178.30.35,67.178.30.36,3260-subnet,cos3260-wf
cde465-04,0c:c4:7a:bb:0d:2a,67.178.5.142,ADMIN,ADMIN,1.1.1.1,2.2.2.2,3.3.3.3,,,,3260-subnet,cos465-wf
cos3260-04,90:e2:ba:e6:96:e4,67.178.3.8,admin,Comcast!23,,67.178.10.122,67.178.10.10,67.178.30.138,67.178.30.35,67.178.30.36,3260-subnet,cos3260-wf
cde465-05,0c:c4:7a:bb:0d:2a,1.1.1.1,ADMIN,ADMIN,1.1.1.1,2.2.2.2,3.3.3.3,,,,3260-subnet,cos465-wf
cos3260-05,0c:c4:7a:bb:0d:2a,67.178.30.38,admin,Comcast!23,,1.1.1.1,2.2.2.2,67.178.30.35,67.178.30.36,67.178.30.36,3260-subnet,cos3260-wf
cde465-06,0c:c4:7a:bb:0d:2a,1.1.1.1,ADMIN,ADMIN,67.178.5.142,1.1.1.1,2.2.2.2,,,,3260-subnet,cos465-wf
cos3260-06,0c:c4:7a:bb:0d:2a,67.178.30.138,admin,Comcast!23,,2.2.2.2,1.1.1.1,67.178.30.35,67.178.30.36,67.178.30.36,3260-subnet,cos3260-wf
cmc-01,6c:41:6a:b1:56:fb,67.178.14.6,,,,,,,,,vlan-342,cmc-wf
```

<table>
<tr><td>host</td><td> mac</td><td> mgmt_ip</td><td> user</td><td> password</td><td> ipmi</td><td> int1</td><td> int2</td><td> cimc</td><td> sioc</td><td> bmc</td><td> subnet</td><td> workflow</td></tr>
<tr><td>cde465-02</td><td>0c:c4:7a:bb:0d:2a</td><td>1.1.1.1</td><td>ADMIN</td><td>ADMIN</td><td>1.1.1.1</td><td>2.2.2.2</td><td>3.3.3.3</td><td></td><td></td><td></td><td>3260-subnet</td><td>cos465-wf</td></tr>
<tr><td>cos3260-01</td><td>90:e2:ba:e6:96:78</td><td>67.178.3.5</td><td>admin</td><td>Comcast!23</td><td></td><td>67.178.10.116</td><td>67.178.10.117</td><td>67.178.30.38</td><td>67.178.30.35</td><td>67.178.30.36</td><td>3260-subnet</td><td>cos3260-wf</td></tr>
<tr><td>cde465-01</td><td>0c:c4:7a:bb:0d:2a</td><td>67.178.3.9</td><td>ADMIN</td><td>ADMIN</td><td>67.178.5.142</td><td>67.178.10.124</td><td>67.178.10.125</td><td></td><td></td><td></td><td>3260-subnet</td><td>cos465-wf</td></tr>
<tr><td>cos3260-02</td><td>90:e2:ba:e6:96:d8</td><td>67.178.3.6</td><td>admin</td><td>Comcast!23</td><td></td><td>67.178.10.118</td><td>3.3.3.3</td><td>67.178.30.138</td><td>67.178.30.35</td><td>67.178.30.36</td><td>3260-subnet</td><td>cos3260-wf</td></tr>
<tr><td>cde465-03</td><td>0c:c4:7a:bb:0d:2a</td><td>1.1.1.1</td><td>ADMIN</td><td>ADMIN</td><td>1.1.1.1</td><td>2.2.2.2</td><td>1.1.1.1</td><td></td><td></td><td></td><td>3260-subnet</td><td>cos465-wf</td></tr>
<tr><td>cos3260-03</td><td>90:e2:ba:e6:97:14</td><td>67.178.3.7</td><td>admin</td><td>Comcast!23</td><td></td><td>67.178.10.120</td><td>67.178.10.121</td><td>67.178.30.38</td><td>67.178.30.35</td><td>67.178.30.36</td><td>3260-subnet</td><td>cos3260-wf</td></tr>
<tr><td>cde465-04</td><td>0c:c4:7a:bb:0d:2a</td><td>67.178.5.142</td><td>ADMIN</td><td>ADMIN</td><td>1.1.1.1</td><td>2.2.2.2</td><td>3.3.3.3</td><td></td><td></td><td></td><td>3260-subnet</td><td>cos465-wf</td></tr>
<tr><td>cos3260-04</td><td>90:e2:ba:e6:96:e4</td><td>67.178.3.8</td><td>admin</td><td>Comcast!23</td><td></td><td>67.178.10.122</td><td>67.178.10.10</td><td>67.178.30.138</td><td>67.178.30.35</td><td>67.178.30.36</td><td>3260-subnet</td><td>cos3260-wf</td></tr>
<tr><td>cde465-05</td><td>0c:c4:7a:bb:0d:2a</td><td>1.1.1.1</td><td>ADMIN</td><td>ADMIN</td><td>1.1.1.1</td><td>2.2.2.2</td><td>3.3.3.3</td><td></td><td></td><td></td><td>3260-subnet</td><td>cos465-wf</td></tr>
<tr><td>cos3260-05</td><td>0c:c4:7a:bb:0d:2a</td><td>67.178.30.38</td><td>admin</td><td>Comcast!23</td><td></td><td>1.1.1.1</td><td>2.2.2.2</td><td>67.178.30.35</td><td>67.178.30.36</td><td>67.178.30.36</td><td>3260-subnet</td><td>cos3260-wf</td></tr>
<tr><td>cde465-06</td><td>0c:c4:7a:bb:0d:2a</td><td>1.1.1.1</td><td>ADMIN</td><td>ADMIN</td><td>67.178.5.142</td><td>1.1.1.1</td><td>2.2.2.2</td><td></td><td></td><td></td><td>3260-subnet</td><td>cos465-wf</td></tr>
<tr><td>cos3260-06</td><td>0c:c4:7a:bb:0d:2a</td><td>67.178.30.138</td><td>admin</td><td>Comcast!23</td><td></td><td>2.2.2.2</td><td>1.1.1.1</td><td>67.178.30.35</td><td>67.178.30.36</td><td>67.178.30.36</td><td>3260-subnet</td><td>cos3260-wf</td></tr>
<tr><td>cmc-01</td><td>6c:41:6a:b1:56:fb</td><td>67.178.14.6</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td>vlan-342</td><td>cmc-wf</td></tr>
</table>


Input csv file Validation tests..
```bash
./clean-inventory.sh full.problem.csv
Validating full.problem.csv field counts
Quick test on full.problem.csv logical fields
Line 2 in full.problem.csv cde465-02 missing required field detected for cos465
Line 3 in full.problem.csv cos3260-01 missing required field detected for cos3260
Line 4 in full.problem.csv cde465-01 missing required field detected for cos465
Line 5 in full.problem.csv cos3260-02 missing required field detected for cos3260
Line 6 in full.problem.csv cde465-03 missing required field detected for cos465
Line 7 in full.problem.csv cos3260-03 missing required field detected for cos3260
Line 9 in full.problem.csv cos3260-04 missing required field detected for cos3260
Line 10 in full.problem.csv cde465-05 missing required field detected for cos465
Line 11 in full.problem.csv cos3260-05 missing required field detected for cos3260
Line 12 in full.problem.csv cde465-06 missing required field detected for cos465
Line 13 in full.problem.csv cos3260-06 missing required field detected for cos3260
Line 14 in full.problem.csv cmc-01 missing required field detected for cmc
Problems detected in full.problem.csv, please correct the file and restart the script
```
