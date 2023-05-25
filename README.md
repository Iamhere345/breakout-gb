# breakout-gb

`breakout-gb` is a homebrew version of [Breakout](https://en.wikipedia.org/wiki/Breakout_(video_game)) for the gameboy.

Based off of the [GB ASM Tutorial](https://gbdev.io/gb-asm-tutorial/index.html)

## Compilation

`breakout-gb` can be compiled using the [RGBDS toolchain](https://rgbds.gbdev.io/)

use the following commands to compile the source code into a valid Gameboy ROM:

```
rgbasm -L -o main.o main.asm
rgblink -o breakout.gb main.o
rgbfix -v -p 0xFF breakout.gb
```

Alternatively, on UNIX systems, you can use the `build.sh` script (with RGBDS installed)
```
./build.sh main.asm main.o breakout
```

## Emulation

This game was tested using the [Emulicious](https://emulicious.net/) Gameboy Emulator, although any emulator should (hopefully) work.

## Todo

The tutorial this is based off is still being written, so i'd like to add some other features not yet mentioned in the tutorial by myself.

Some ideas include:
 - A score counter
 - a life system, where when you miss the ball you lose a life
 - music and sfx
 - levels (different arrangements of bricks)