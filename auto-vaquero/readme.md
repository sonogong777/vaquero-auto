# AUTO Vaguero 
 Attempting to automate Cisco COS deployemnt 

Currently implemented steps..
1.	Validates csv file for field counts and brief logic check. Example, if ipmi field exist then check for two interface configuration etc.
2.	Check for existing entry in the inventory file an remove them if identified.  This is a confirmed test that we can remove a configuration block form inventory file.
3.	Update inventory files with configuration.  (cos3260,cos465,cmc)
4.	Initialize pre install steps, ipmi for 465 and cimc for 3260.

Pending items:
1. Preinstallation requirements for CMC and possibly other components.
2. Confirmation steps post application registration to remove the entry from inventory to prevent PXE boot.
3. Possibly a UI dash board instead of colorized CLI output.

<H3> Usage </H3>

```bash
  ./auto-vaquero.sh
  Usage: ./auto-vaquero.sh <csv file name>
  example: ./auto-vaquero.sh test.csv
```

<a href="https://github.com/sonogong777/vaquero-auto/blob/master/auto-vaquero/inventory.yml"> Updated inventory.yaml </a>



Sample Execution:

```bash
./auto-vaquero.sh full.csv
Validating full.csv field counts
Quick test on full.csv logical fields
cde465-02, starting initial deployment
cos3260-01, starting initial deployement
cde465-01, starting initial deployment
cos3260-02, starting initial deployement
cde465-03, starting initial deployment
cos3260-03, starting initial deployement
cde465-04, starting initial deployment
cos3260-04, starting initial deployement
cde465-05, starting initial deployment
cos3260-05, starting initial deployement
cde465-06, starting initial deployment
cos3260-06, starting initial deployement
cmc-01, starting initial deployement
```
```diff
+ cde465-01:Configuration added to inventory successfully, continuing with ipmi
+ cos3260-02:Configuration added to inventory successfully, continuing with cimc
+ cde465-05:Configuration added to inventory successfully, continuing with ipmi
+ cos3260-04:Configuration added to inventory successfully, continuing with cimc
+ cos3260-03:Configuration added to inventory successfully, continuing with cimc
+ cos3260-01:Configuration added to inventory successfully, continuing with cimc
+ cmc-01:Configuration added to inventory successfully, NEXT STEP?
+ cde465-02:Configuration added to inventory successfully, continuing with ipmi
+ cde465-03:Configuration added to inventory successfully, continuing with ipmi
+ cde465-04:Configuration added to inventory successfully, continuing with ipmi
+ cos3260-05:Configuration added to inventory successfully, continuing with cimc
+ cos3260-06:Configuration added to inventory successfully, continuing with cimc
+ cde465-06:Configuration added to inventory successfully, continuing with ipmi
```
```diff
- cos3260-02: Error detected, please review the pre.cos3260-02.log for details
- cde465-05: Error detected check pre.cde465-05.log
- cde465-02: Error detected check pre.cde465-02.log
- cde465-03: Error detected check pre.cde465-03.log
- cde465-04: Error detected check pre.cde465-04.log
+ cde465-01: IPMI system reboot successful
+ cde465-06: IPMI system reboot successful
- cos3260-04: Error detected, please review the pre.cos3260-04.log for details
- cos3260-01: Error detected, please review the pre.cos3260-01.log for details
+ cos3260-03: ./preinst_setup_UCSC-C3KIOE_2x10.sh script completed successfully
- cos3260-04: Error detected, please review the pre.cos3260-04.log for details
- cos3260-01: Error detected, please review the pre.cos3260-01.log for details
+ cos3260-03: ./preinst_setup_UCSC-C3KIOE_2x10.sh script completed successfully
+ cos3260-06: ./preinst_setup_UCSC-C3KIOE_2x10.sh script completed successfully
+ cos3260-05: ./preinst_setup_UCSC-C3KIOE_2x10.sh script completed successfully
```




Input file format: 
Sample csv file full.csv
```bash
host, mac, mgmt_ip, user, password, ipmi, int1, int2, cimc, sioc, bmc
cde465-02,123,1.1.1.1,ADMIN,ADMIN,1.1.1.1,2.2.2.2,3.3.3.3,,,
cos3260-01,90:e2:ba:e6:96:78,67.178.3.5,admin,Comcast!23,,67.178.10.116,67.178.10.117,67.178.30.38,67.178.30.35,67.178.30.36
cde465-01,0c:c4:7a:bb:0d:2a,67.178.3.9,ADMIN,ADMIN,67.178.5.142,67.178.10.124,67.178.10.125,,,
cos3260-02,90:e2:ba:e6:96:d8,67.178.3.6,admin,Comcast!23,,67.178.10.118,3.3.3.3,67.178.30.138,67.178.30.35,67.178.30.36
cde465-03,123,1.1.1.1,ADMIN,ADMIN,1.1.1.1,2.2.2.2,1.1.1.1,,,
cos3260-03,90:e2:ba:e6:97:14,67.178.3.7,admin,Comcast!23,,67.178.10.120,67.178.10.121,67.178.30.38,67.178.30.35,67.178.30.36
cde465-04,123,67.178.5.142,ADMIN,ADMIN,1.1.1.1,2.2.2.2,3.3.3.3,,,
cos3260-04,90:e2:ba:e6:96:e4,67.178.3.8,admin,Comcast!23,,67.178.10.122,67.178.10.123,67.178.30.138,67.178.30.35,
cde465-05,123,1.1.1.1,ADMIN,ADMIN,1.1.1.1,2.2.2.2,3.3.3.3,,,
cos3260-05,123,67.178.30.38,admin,Comcast!23,,1.1.1.1,2.2.2.2,67.178.30.35,67.178.30.36,
cde465-06,123,1.1.1.1,ADMIN,ADMIN,67.178.5.142,1.1.1.1,2.2.2.2,,,
cos3260-06,123,67.178.30.138,admin,Comcast!23,,2.2.2.2,1.1.1.1,67.178.30.35,67.178.30.36,
cmc-01,6c:41:6a:b1:56:fb,67.178.14.6,,,,,,,,
```

<table>
<tr><td>host</td><td> mac</td><td> mgmt_ip</td><td> user</td><td> password</td><td> ipmi</td><td> int1</td><td> int2</td><td> cimc</td><td> sioc</td><td> bmc</td></tr>
<tr><td>cde465-02</td><td>123</td><td>1.1.1.1</td><td>ADMIN</td><td>ADMIN</td><td>1.1.1.1</td><td>2.2.2.2</td><td>3.3.3.3</td><td></td><td></td><td></td></tr>
<tr><td>cos3260-01</td><td>90:e2:ba:e6:96:78</td><td>67.178.3.5</td><td>admin</td><td>Comcast!23</td><td></td><td>67.178.10.116</td><td>67.178.10.117</td><td>67.178.30.38</td><td>67.178.30.35</td><td>67.178.30.36</td></tr>
<tr><td>cde465-01</td><td>0c:c4:7a:bb:0d:2a</td><td>67.178.3.9</td><td>ADMIN</td><td>ADMIN</td><td>67.178.5.142</td><td>67.178.10.124</td><td>67.178.10.125</td><td></td><td></td><td></td></tr>
<tr><td>cos3260-02</td><td>90:e2:ba:e6:96:d8</td><td>67.178.3.6</td><td>admin</td><td>Comcast!23</td><td></td><td>67.178.10.118</td><td>3.3.3.3</td><td>67.178.30.138</td><td>67.178.30.35</td><td>67.178.30.36</td></tr>
<tr><td>cde465-03</td><td>123</td><td>1.1.1.1</td><td>ADMIN</td><td>ADMIN</td><td>1.1.1.1</td><td>2.2.2.2</td><td>1.1.1.1</td><td></td><td></td><td></td></tr>
<tr><td>cos3260-03</td><td>90:e2:ba:e6:97:14</td><td>67.178.3.7</td><td>admin</td><td>Comcast!23</td><td></td><td>67.178.10.120</td><td>67.178.10.121</td><td>67.178.30.38</td><td>67.178.30.35</td><td>67.178.30.36</td></tr>
<tr><td>cde465-04</td><td>123</td><td>67.178.5.142</td><td>ADMIN</td><td>ADMIN</td><td>1.1.1.1</td><td>2.2.2.2</td><td>3.3.3.3</td><td></td><td></td><td></td></tr>
<tr><td>cos3260-04</td><td>90:e2:ba:e6:96:e4</td><td>67.178.3.8</td><td>admin</td><td>Comcast!23</td><td></td><td>67.178.10.122</td><td>67.178.10.123</td><td>67.178.30.138</td><td>67.178.30.35</td><td></td></tr>
<tr><td>cde465-05</td><td>123</td><td>1.1.1.1</td><td>ADMIN</td><td>ADMIN</td><td>1.1.1.1</td><td>2.2.2.2</td><td>3.3.3.3</td><td></td><td></td><td></td></tr>
<tr><td>cos3260-05</td><td>123</td><td>67.178.30.38</td><td>admin</td><td>Comcast!23</td><td></td><td>1.1.1.1</td><td>2.2.2.2</td><td>67.178.30.35</td><td>67.178.30.36</td><td></td></tr>
<tr><td>cde465-06</td><td>123</td><td>1.1.1.1</td><td>ADMIN</td><td>ADMIN</td><td>67.178.5.142</td><td>1.1.1.1</td><td>2.2.2.2</td><td></td><td></td><td></td></tr>
<tr><td>cos3260-06</td><td>123</td><td>67.178.30.138</td><td>admin</td><td>Comcast!23</td><td></td><td>2.2.2.2</td><td>1.1.1.1</td><td>67.178.30.35</td><td>67.178.30.36</td><td></td></tr>
<tr><td>cmc-01</td><td>6c:41:6a:b1:56:fb</td><td>67.178.14.6</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
</table>



Input csv file Validation tests..
```bash
./auto-vaquero.sh full.problem.csv
Validating full.problem.csv field counts
Quick test on full.problem.csv logical fields
Line 2 in full.problem.csv cde465-02 missing required field detected for cos465
Line 6 in full.problem.csv cde465-03 missing required field detected for cos465
Line 10 in full.problem.csv cde465-05 missing required field detected for cos465
Line 11 in full.problem.csv cos3260-05 missing required field detected for cos3260
Line 12 in full.problem.csv cde465-06 missing required field detected for cos465
Line 13 in full.problem.csv cos3260-06 missing required field detected for cos3260
Problems detected in full.problem.csv, please correct the file and restart the script
[root@vaquero-vm2 ~]# cat pre.csv.log
2017/10/04:17:14:08 Validating full.problem.csv field counts
2017/10/04:17:14:08 Quick test on full.problem.csv logical fields
2017/10/04:17:14:08 ERROR: Line 2 in full.problem.csv cde465-02 missing required field detected for cos465
2017/10/04:17:14:08 ERROR: Line 6 in full.problem.csv cde465-03 missing required field detected for cos465
2017/10/04:17:14:08 ERROR: Line 10 in full.problem.csv cde465-05 missing required field detected for cos465
2017/10/04:17:14:08 ERROR: Line 11 in full.problem.csv cos3260-05 missing required field detected for cos3260
2017/10/04:17:14:08 ERROR: Line 12 in full.problem.csv cde465-06 missing required field detected for cos465
2017/10/04:17:14:08 ERROR: Line 13 in full.problem.csv cos3260-06 missing required field detected for cos3260
2017/10/04:17:14:08 Problems detected in full.problem.csv, please correct the file and restart the script.
2017/10/04:17:14:08 Check pre.csv.log for additional detail
```
