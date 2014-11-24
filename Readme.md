## Title: reactorControl
**Avaliable at: http://pastebin.com/gFqTUvzM**

## Author: Tad DeVries <tad@splunk.net>
Copyright (C) 2013-2014 Tad DeVries <tad@splunk.net>
http://tad.mit-license.org/2014

## Description
A Big Reactors control program that monitors multiple reactors and modifies
their control rod settings based on the amount of energy stored in the
internal buffer of the reactor. By default the program will check all the
connected reactors every 5 seconds, when the internal buffer of a reactor
is at or above 80% capacity the control rods will start to lower to slow the
the reaction speed until their are at 100% inserted. Some basic information
is displayed on the computer terminal while this program is running showing
the status of connected reactors. Because of the limited space in a terminal
only 16 reactors will be displayed.

## Use
This program should work by just placing a computer next to the computers
port on a reactor. However I built this with the idea that multiple
reactors would be connected via a wired computer network.

## Method of Operation
Connect a computer to the computer port on one or more reactors either
directly or through a wired computer network. Name this program *startup*
then reboot the computer.