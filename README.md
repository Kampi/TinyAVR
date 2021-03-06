# TinyAVR

## Table of Contents

- [TinyAVR](#tinyavr)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
  - [Files](#files)
  - [Supported instructions](#supported-instructions)
  - [History](#history)
  - [Maintainer](#maintainer)

## About

![Title](images/Title.png)

VHDL-based implementation of an Atmel / Microchip [AVR](https://en.wikipedia.org/wiki/AVR_microcontrollers) compatible CPU.

## Files

- `scripts`
  - `Intel2Hex` : Python application to convert a compiled AVR application from [Intel Hex Format](https://en.wikipedia.org/wiki/Intel_HEX) to a Hex-File for the program memory of the Vivado project.
- `software`
  - `AVRASM` : Source files and compiled assembly applications to test the CPU core.
- `hardware` : The CPU core project.

## Supported instructions

Check `hardware/TinyAVR.srcs/sources_1/new/Packages/Opcodes.vhd` to get a brief overview of the supported Opcodes.

## History

| **Version** | **Description** | **Date** |
|-------------|-----------------|----------|
| 1.0         | Initial release |          |

## Maintainer

- [Daniel Kampert](mailto:DanielKampert@kampis-elektroecke.de)
