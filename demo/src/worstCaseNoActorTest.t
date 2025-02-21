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

	toggleDoors() {
/*
		local d0, d1, i;

		for(i = 1; i <= doorList.length; i += 4) {
			if((rand(100) + 1) < 90) continue;
			if((rand(100) + 1) < 50) {
				d0 = i;
				d1 = i + 2;
				//d0 = doorList[i];
				//d1 = doorList[i - 1];
			} else {
				d0 = i + 2;
				d1 = i;
				//d0 = doorList[i - 1];
				//d1 = doorList[i];
			}
			_toggleDoor(d0, true);
			_toggleDoor(d1, nil);
		}
*/
	}

	_toggleDoor(idx, st) {
/*
		local d0, d1;

		d0 = doorList[idx];
		d1 = doorList[idx + 1];

		d0.makeLocked(st);

		gameMain.updatePathfinder(d0);
		gameMain.updatePathfinder(d1);
*/
	}

	newGame() {
		local rm;

		doorDaemon = new Daemon(self, &toggleDoors, 1);

		if((rm = worstCase.getRandomRoom()) != nil)
			initialPlayerChar.moveInto(rm);

		inherited();
	}
;

pathfinder: RoomPathfinder
	initializeFastPath() {
		inherited();
		resetFastPath();
	}
;

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

modify WorstCaseMapGenerator
	addWorstCaseActors() { return(true); }
;

modify worstCaseAfter
	_count = nil
	executeTurn() {
		computePaths();
		inherited();
	}
	computePaths() {
		local i, l, rm0, rm1;

		if(_count == nil) {
			_count = 0;
			worstCase.zones.forEach({ x: _count += x._mapSize });
		}
		for(i = 0; i < _count; i++) {
			rm0 = worstCase.getRandomRoom();
			rm1 = nil;
			while((rm1 == nil) || (rm0 == rm1))
				rm1 = worstCase.getRandomRoom();
			l = worstCase.findPath(me, rm0, rm1);
			//l = roomPathFinder.findPath(me, rm0, rm1);
			if(l) {}
		}
	}
;
me: Person;
