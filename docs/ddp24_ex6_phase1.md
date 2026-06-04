
# DDP24 Exercise #6 stage 2
In the stage we will update the environment including a baseline for the ascii_art SW acceleration assignment.

## Prerequisite

Prior to this assignment you should have accomplished the first stage assignment of installation and experiencing helloworld execution.  
[as guided here](https://gitlab.com/udik/ddp23_pnx/-/blob/main/README.md?ref_type=heads)

## Updating the environment
open a new terminal and execute:
```bash
tsmc65  
cd $PULP_ENV
```

### Updating the  Repository:
**CAUTION!!!**
~~~
Following commands will overwrite your reccent modifications to the environment.
Since we do not support students deposits to the git repository
To save your work you need to backup it out of your repository.
Example: If you wish to save your modified helloworld from last week do this:
~~~

```bash
mkdir $PULP_ENV/../backups ;# Create backup folder out sade of the repo area (just once)
mv $PULP_ENV/src/ips/pulpenix_sw/apps/helloworld $PULP_ENV/../backups
git stash ;# revert local modifications since last clone pull (and also save them locally for potential pop)
git pull ; # Fully Update from repository main branch
```

### Run ascii-art
Open a new terminal (in case not already opened) and execute:
```bash
tsmc65
cd $PULP_ENV/../sim
ddp23_make APP=ascii_art
cat ascii_art_out.txt ;# Display the generated ASCII ART file
```
~~~
The result is almost good but as you may notice the overlap font parts are not properly handled
Well, you are going to fix it soon.
~~~

### Check both accelerated and non-accelerated modes
Edit the C file: (use bscode or your preferred text eitor)
```bash
code $MY_DDP23_APPS/ascii_art/ascii_art.c
```
~~~
Go to the "main" function , to line 196, and  modify acceleration enabling to 0 (disabled)
int is_xltr_enabled = 0 ; // 1: enabled ; 0: disabled
save the file and rerun the application
~~~
```bash
ddp23_make APP=ascii_art
```
~~~
Notice the reported cycle count difference.
display the generated ascii_art file:
cat ascii_art_out.txt ;# Display the generted ASCII ART file
Notice, that for the SW version the ovelapping parts are handled correctly.
~~~
### Assignment:
~~~
edit $MY_DDP23_APPS/ascii_art/ascii_art.c and and  modify acceleration enabling back to 1 (enabled)
int is_xltr_enabled = 1 ; // 1: enabled ; 0: disabled
Fix the missing handling of fonts overlapping section.

Edit the acceleration System-Verilog module:
code $PULP_ENV/src/ips/xbox/xbox_xlr_aa.sv

At the bottom of the file you wil find the combination function for manipulating the image as described in the lecture.

Carefully modify this function (do not change its interface!) 
such that overlapping fonts are properly handled as described in exercise 5.
Do notice that some of the constant parameters have slightly changed from ex.5 (e.g. width of font) 
so make sure you use the parameter names rather than acrtual values.
~~~
Good luck,
Udi






