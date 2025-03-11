#charset "us-ascii"
//
// worstCaseTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This demo is intended to be a performance test for the fastPath library.
//
// This variation on the test doesn't move any actors, it just computes
// several hundred random paths per turn.  This is intended to isolate
// the time spent on pathfinding versus moving objects around the
// gameworld.
//
// It can be compiled via the included makefile with
//
//	# t3make -f worstCaseTest.t3m
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

#include "worstCase.h"
#ifndef WORST_CASE_H
#error "This demo requires the worstCase module. "
#endif // WORST_CASE_H

versionInfo: GameID;
gameMain: GameMainDef
	// Standard adv3.  The default player character.
	initialPlayerChar = me

	doorDaemon = nil

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(5)); }

	newGame() {
		local rm;

		pathfinder.resetFastPath();

		// Pick a random room and dump the player in it.
		if((rm = worstCase.getRandomRoom()) != nil)
			initialPlayerChar.moveInto(rm);

		inherited();
	}
;

pathfinder: RoomPathfinder;

// Update the worstCase pathfinder to use fastPath.
modify worstCase
	execAfterMe = (nilToList(inherited()) + [ fastPathAutoInit ])

	findPath(actor, rm0, rm1) {
		return(pathfinder.findPath(rm0, rm1));
	}
;

modify WorstCaseRoom
	fastPathZone = ('zone' + simpleRandomMapGenerator.zoneNumber)
;

// Tweak the generator to skip adding actors.
modify WorstCaseMapGenerator
	addWorstCaseActors() { return(true); }
;

// Schedulable object that does stuff after every turn.
// Here we pick a bunch of random rooms and compute paths between them.
// The idea here is that we're replicating the number of pathfinding tasks
// in the "normal" worst case test, but we're not moving a bunch of
// actors around.  This is to isolate the cost of pathfinding itself
// versus the cost of updating a whole bunch of in-game objects.
modify worstCaseAfter
	_count = nil		// number of paths to compute.

	executeTurn() {
		computePaths();
		inherited();
	}

	// Compute a bunch of random paths.
	computePaths() {
		local i, l, rm0, rm1;

		// If we haven't run before we figure out the number of
		// paths to compute each turn.  This will end up being
		// the same as the number of rooms in the map, which is
		// also the total number of randomly-moving actors in
		// the "real" worst-case test.
		if(_count == nil) {
			_count = 0;
			worstCase.zones.forEach({ x: _count += x._mapSize });
		}

		// Now compute the paths.
		for(i = 0; i < _count; i++) {
			// Get two different random rooms.
			rm0 = worstCase.getRandomRoom();
			rm1 = nil;
			while((rm1 == nil) || (rm0 == rm1))
				rm1 = worstCase.getRandomRoom();

			// Find the path between them.
			l = worstCase.findPath(me, rm0, rm1);

			// Useless conditional so the compiler doesn't
			// complain that we assigned a variable we
			// didn't use.
			if(l) {}
		}
	}
;

me: Person;
