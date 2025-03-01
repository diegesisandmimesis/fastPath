#charset "us-ascii"
//
// randomMapTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
//
// This just generates a random map, picks two random rooms in it, and
// then tries to compute the path between them.  This is intended as
// a test of minimal functionality with a non-trivial map.
//
// It can be compiled via the included makefile with
//
//	# t3make -f randomMapTest.t3m
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

#include "simpleRandomMap.h"
#ifndef SIMPLE_RANDOM_MAP_H
#error "This demo requires the simpleRandomMap module. "
#endif // SIMPLE_RANDOM_MAP_H

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	// Returns a random room from the procgen map.
	pickRandomRoom() { return(map._getRoom(rand(map._mapSize) + 1)); }

	newGame() {
		local l, rm0, rm1;

		// Pick two random rooms.
		rm0 = pickRandomRoom();
		rm1 = pickRandomRoom();

		// Try to find a path between them.
		l = pathfinder.findPath(rm0, rm1);

		// See if it worked.
		if(pathfinder.testPath(rm0, rm1, l))
			"Passed test\n ";
		else
			"ERROR: pathfinding failed\n ";
	}
;

me: Person;

pathfinder: RoomPathfinder;
map: SimpleRandomMapGenerator movePlayer = nil;
