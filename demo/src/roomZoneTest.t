#charset "us-ascii"
//
// zoneTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
//
// This is a minimal test of zone-aware pathfinding using a tiny,
// trivial map.
//
// It can be compiled via the included makefile with
//
//	# t3make -f zoneTest.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		if(pathfinder.verifyPath(startRoom, exitRoom, [
				startRoom, foo1, foo2, foo3, bar1, bar2, bar3,
				exitRoom
			])) {
			"test passed\n ";
		} else {
			"pathfinding FAILED\n ";
		}
	}
;

me: Person;

pathfinder: RoomPathfinder;

class Foo: Room 'Foo' "This is a foo room. " fastPathZone = 'foo';
class Bar: Room 'Bar' "This is a bar room. " fastPathZone = 'bar';
startRoom: Room 'start' "This is the start room." fastPathZone = 'start'
	north = foo1;
foo1: Foo 'foo1' north = foo2 south = startRoom;
foo2: Foo 'foo2' north = foo3 south = foo1;
foo3: Foo 'foo3' north = bar1 south = foo2;
bar1: Bar 'bar1' north = bar2 south = foo3;
bar2: Bar 'bar2' north = bar1 south = bar3;
bar3: Bar 'bar3' north = exitRoom south = bar2;
exitRoom: Room 'exit' "This is the exit room." fastPathZone = 'exit'
	south = bar3;
