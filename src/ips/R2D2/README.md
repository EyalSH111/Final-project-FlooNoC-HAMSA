## Overview

The Research 2 Development 2-lset is a modular python package that allows for unified programming and interactivity through a variety of growing and easily expandable protocols. It meant to allow for testing and programming of ENICS research projects.

## Getting Started

### Prerequisites

Required:
- git
- python3
- pyserial (downloadable using pip)
- A communication cable and port (protocol and platform dependent)

Recommended:
- A python environment and editor allowing for debugging.

### Downloading

To download R2D2, first change to your workspace/project/simulation directory, and then issue following command:

```bash
git clone git@gitlab.local:soc/R2D2.git
```

## Usage

### Initialization

To use R2D2, ```import R2D2``` must appear at the top of the script meant to use it. After that, a R2D2 object can be created in the following manner:
```python
a = r2d2.Command(r2d2.Interface, *args)
```
where each ```*args``` is replaced the arguments needed for the specified protocol.  

Alternatively (BROKEN), a chip dependent child class be used:

```python
a = negev.Negev('uart')
``` 

### Protocol Arguments

uart:

- port
- baudrate

socket:
- ip
- port

### Base Functions

```python
read(address)
```
Will return the value stored at the given address

```python
write(address, value)
```
Will write value to the given address

## Development

### Creating presets for a new chip/implementation

In order to add a new chip preset that can be accessed by simply importing said chip's name, a folder with the chips name must contain the following:
```python
#in __init__.py

import r2d2


class chip_name(r2d2.R2D2):
    def __init__(self, preset='default'):
        if preset == 'preset1':
            r2d2.R2D2.__init__(self, *args)
        if preset == 'preset2':
            r2d2.R2D2.__init__(self, *args)
```

### Creating/Adding address mapping to a chip configuration/preset 

In order to add address mapping to a chip configuration, a folder with the chips name must contain the following:

```python
#in address.py

MAPPING = 0xdeadbeef
```
It can than be accessed using:
```python
from chip_name.address import *
```

### Adding support for a new protocol/interface

In order to add a new interface, the following must be placed into a file named r2d2_[interface].py (where 
interface is replaced by the name of the interface):

```python
import interface_library

class interface(interface):
    def __init__(self, interface_args):
        # constructor code here
    def __del__(self):
        # destructor code here

    def puts(self, message):
        # send message through interface

    def gets(self, size=1):
        # return received message through interface
```


### Contributing to the project;

//TODO