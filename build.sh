#!/bin/bash

# args: main.asm main.o out.gb/sym (WITHOUT EXTENSION)

rgbasm -L -o $2 $1
rgblink -o $3.gb $2
rgblink -n $3.sym $2
rgbfix -v -p 0xFF $3.gb