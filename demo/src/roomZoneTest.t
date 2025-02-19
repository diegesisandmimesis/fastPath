#charset "us-ascii"
//
// zoneTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
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

#include <date.h>
#include <bignum.h>

#include "fastPath.h"

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(3)); }

	newGame() {
		local l;

		"\n<.p>\n ";
		pathfinder.createFastPathCache();
		//local l = pathfinder.findPath('start', 'exit');
		l = pathfinder.findPath(startRoom, exitRoom);
		"\nPath:\n ";
		if(l == nil) {
			"\n\tno path\n ";
			return;
		}
		l.forEach(function(o) {
			"\n\t<<toString(o.name)>>\n ";
		});
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
