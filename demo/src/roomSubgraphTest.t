#charset "us-ascii"
//
// roomSubgraphTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is indended as a minimialistic test of zone-aware pathfinding.
// In particular we define our own object class, instead of using Room,
// to exercise the non-room-based zone pathfinding code.
//
// It can be compiled via the included makefile with
//
//	# t3make -f roomSubgraphTest.t3m
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

	newGame() {
		local l;

		l = pathfinder.findPath(foo1, bar3);
		if(pathfinder.testPath(foo1, bar3, l)) {
			"\npassed all tests\n ";
		} else {
			"\npathfinding FAILED\n ";
		}
		//inherited();
	}
;

me: Person;

// Pathfinder.  Nothing interesting happening here.
pathfinder: RoomPathfinder fastPathObjectClass = DemoRoom;

// Room class.  Not really needed for the demo as written, but having
// descriptions and names helps if it needs to be interactively debugged.
class DemoRoom: Room
	desc = "This is a room in the <<fastPathZone>> zone. "
	name = 'Room <<fastPathID>>'
;

// We create subclasses so we only have to declare the zone ID once each.
// In this case foo and bar rooms start in the same zone, which is a
// problem that will have to be fixed.
class FooRoom: DemoRoom fastPathZone = 'zoneX';
class BarRoom: DemoRoom fastPathZone = 'zoneX';
class BazRoom: DemoRoom fastPathZone = 'zoneY';

// Rooms.  Basic map is just a straight west to east line starting
// at foo1 and going to bar3, with baz1 between the foo rooms and the
// bar rooms.
// The motivation is to start out with "zoneX" being the foo and bar
// rooms and "zoneY" being the single baz room.  The pathfinder
// needs rooms in zones to be contiguous (every room in the zone in
// reachable from every other room in the zone via a path entirely
// inside the zone).  In this case that isn't true, and what we're
// testing is the RoomPathfinder classes' logic for detecting and
// correcting this problem.
foo1: FooRoom fastPathID = 'foo1' east = foo2;
foo2: FooRoom fastPathID = 'foo2' east = foo3 west = foo1;
foo3: FooRoom fastPathID = 'foo3' east = baz1 west = foo2;
bar1: BarRoom fastPathID = 'bar1' east = bar2 west = baz1;
bar2: BarRoom fastPathID = 'bar2' east = bar3 west = bar1;
bar3: BarRoom fastPathID = 'bar3' west = bar2;
baz1: BazRoom fastPathID = 'baz1' east = bar1 west = foo3;
