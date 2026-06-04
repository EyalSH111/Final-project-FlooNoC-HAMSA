
# DDP24 Exercise #6 stage 3
In the stage you are asked to add a verilog code for horizontally flipping the ascii-art output image.

## Prerequisite

Prior to this assignment you should have accomplished the first stage assignment of installation and experiencing helloworld execution.  
[as guided here](https://gitlab.com/udik/ddp23_pnx/-/blob/main/README.md?ref_type=heads)  
and the second stage of handling overlap pixels as guided here  
[as guided here](https://gitlab.com/udik/ddp23_pnx/-/blob/main/docs/ddp24_ex6_phase1.md?ref_type=heads)  

## Updating the environment
~~~
You should again update the environment for this phase, as we added some code to assit you.  
open a new terminal and execute:  
~~~
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
### Provided C code for SW only image flipping
~~~
We have included a full SW only solution for flipping the image which you can explore.  
Look at the provided updated src/ips/pulpenix_sw/apps/ascii_art/ascii_art.c

following flags determine if in acceleration mode and flip mode  
  int is_xltr_enabled = 0 ; // 1: enabled ; 0: disabled  
  char flip_horiz = 1 ;     // Optionally flip image horizontally  

The C SW (non accelerated) flipping code is at function gen_aa_char_nox
Study this implementation, it can inspire your HW accelerated flipping solution.

The outcome ascii_art image at ascii_art_out.txt in your simulation environment should look as follow

       ________    ________    ________    ________    ________    ________ 
      /  __   /|  /  __   /|  /  __   /|  /  __   /|  /  __   /|  /____   /|
     /  /|/  / / _\ /|/  / / /  /|/  / / _\ /|/  / / /  /|/  / / _|___/  / /
    /  __   / / /  __   / / /  __   / / /  __   / / /  __   / / /  _____/ / 
   /  / /  / / /  /|/  / / /  / /  / / /  /|/  / / /  / /  / / /  /|____|/  
  /__/ /__/ / /_______/ / /__/ /__/ / /_______/ / /__/ /__/ / /  /_/____    
  |__|/|__|/  |_______|/  |__|/|__|/  |_______|/  |__|/|__|/ /_________/|   
                                                             |_________|/   
~~~

### Run ascii-art SW mode
Open a new terminal (in case not already opened) and execute:  
```bash
tsmc65
cd $PULP_ENV/../sim
ddp23_make APP=ascii_art
cat ascii_art_out.txt ;# Display the generated ASCII ART file
```
### Assignment:
~~~
edit $MY_DDP23_APPS/ascii_art/ascii_art.c and and  modify 
acceleration enabling back to 1 (enabled)
int is_xltr_enabled = 1 ; // 1: enabled ; 0: disabled
Keep the flipping request on.
char flip_horiz = 1 ; // Optionally flip image horizontally 

We now have to add the HW flipping code.

Edit the acceleration System-Verilog module:
code $PULP_ENV/src/ips/xbox/xbox_xlr_aa.sv

You will notice we already added a state called FLIP_IMG entered just before writing back the image to the memory
This stage also invokes a new added included verilog function named FLIP_HORIZ_AA_IMG for flipping the image (around line 357)

In this function you will find following place holder section for your flipping code :
...
  // STUDENT FLIPPING VERILOG FUNCTION CODE HERE
     ... 
  // END OF STUDENT FLIPPING VERILOG FUNCTION CODE
...

Within this section implement your verilog flipping code, 
which should achieve the same output image as in the SW implementation refereed above.
Upon completion check your achieved accelerated reported performance compare to the SW solution
by setting the is_xltr_enabled flag in the C code accordingly.

~~~
Good luck,
Udi




