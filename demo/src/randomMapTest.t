#charset "us-ascii"
//
// randomMapTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
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

#include <date.h>
#include <bignum.h>

#include "fastPath.h"

#include "simpleRandomMap.h"
#ifndef SIMPLE_RANDOM_MAP_H
#error "This demo requires the simpleRandomMap module. "
#endif // SIMPLE_RANDOM_MAP_H

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(3)); }

	pickRandomRoom() {
		return(map._getRoom(rand(map._mapSize) + 1));
	}

	newGame() {
		local l, rm0, rm1;

		pathfinder.createFastPathCache();
		rm0 = pickRandomRoom();
		rm1 = pickRandomRoom();
		l = pathfinder.findPath(rm0, rm1);
		if(pathfinder.testPath(rm0, rm1, l))
			"Passed test\n ";
		else
			"ERROR: pathfinding failed\n ";
	}
;

me: Person;

pathfinder: RoomPathfinder;

map: SimpleRandomMapGenerator
	movePlayer = nil
;
