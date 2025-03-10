#charset "us-ascii"
//
// worstCaseTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This demo is intended to be a performance test for the fastPath library.
// It features four hundred rooms and four hundred actors.
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

me: Person;

versionInfo: GameID;
gameMain: GameMainDef
	// Standard adv3.  The default player character.
	initialPlayerChar = me

	doorDaemon = nil

	playerInCorner = true
	useDoors = true

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(5)); }

	toggleDoors() {
		local d0, d1, i, n;

		if(!useDoors)
			return;

		n = 0;

		for(i = 1; i <= worstCase.doorList.length; i += 4) {
			if((rand(100) + 1) < 90) continue;
			if((rand(100) + 1) < 50) {
				d0 = i;
				d1 = i + 2;
			} else {
				d0 = i + 2;
				d1 = i;
			}

			worstCase.toggleDoor(d0, true,
				{ x: gameMain.updateDoors(x) });
			worstCase.toggleDoor(d1, nil,
				{ x: gameMain.updateDoors(x) });
			n += 4;
		}
		//aioSay('\nupdating <<toString(n)>> doors (<<toString(libGlobal.totalTurns)>>)\n ');
	}

	updateDoors(lst) {
		if(!isCollection(lst))
			return;
		lst.forEach({ x: pathfinder.updatePathfinder(x) });
	}

	newGame() {
		local rm, z;

		pathfinder.resetFastPath();
		doorDaemon = new Daemon(self, &toggleDoors, 1);

		if(playerInCorner) {
			// Place the player in the last room of the lower left
			// zone.  This should be a corner shared with two other
			// zones (if we're not in a 1x1 map).  This is useful
			// for monitoring the zone connections.
			z = worstCase.zones[worstCase.zones.length -
				worstCase.zoneWidth + 1];
			if(z != nil)
				rm = z._getRoom(z._mapSize);
		} else {
			// Put the player in a random room.
			rm = worstCase.getRandomRoom();
		}

		if(rm != nil)
			initialPlayerChar.moveInto(rm);

		inherited();
	}
;

pathfinder: RoomPathfinder;

// Update the worstCase pathfinder to use fastPath.
modify worstCase
	execAfterMe = (nilToList(inherited()) + [ fastPathAutoInit ])
	useDoors = (gameMain.useDoors)
	findPath(actor, rm0, rm1) {
		return(pathfinder.findPath(rm0, rm1));
	}
;

modify WorstCaseRoom
	fastPathZone = ('zone' + simpleRandomMapGenerator.zoneNumber)
;

modify WorstCaseMapGenerator mapWidth = 10;
//modify WorstCaseMapGenerator mapWidth = 8;

modify WorstCaseAgenda
	fastPathMoveFailure(e) {
		aioSay('\n===MOVEMENT FAILURE===\n ');
	}
;

/*
modify RoomPathfinder
	executeTurn() {
		aioSay('\nFlushing queue\n ');
		inherited();
	}
;
*/
