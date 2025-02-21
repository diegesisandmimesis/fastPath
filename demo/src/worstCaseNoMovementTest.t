#charset "us-ascii"
//
// worstCaseNoMovementTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This demo is intended to be a performance test for the fastPath library.
//
// This demo is like worstCastTest but the NPCs do pathfinding but don't
// move.  This is to help isolate the performance hit associated with
// movement versus pathfinding.
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

modify WorstCaseAgenda
	invokeItem() {
		local a, d, l, rm0, rm1;

		// Base chance of doing nothing 25% of the time.
		if(wcRand(1, 100) <= 25) return;

		// Make sure we can determine where we are.
		if((a = getActor()) == nil) return;
		if((rm0 = a.getOutermostRoom()) == nil) return;

		// Pick someone to follow if we're not already following
		// someone.
		if(targetActor == nil) pickTarget();

		// Make sure we know where we want to go.
		if((rm1 = getTargetRoom()) == nil) return;

		// If we're already there, nothing to do.
		if(rm0 == rm1) return;

		// Get the path to the target room.
		l = worstCase.findPath(a, rm0, rm1);
		if((l == nil) || (l.length < 2)) return;

		// If we want to return to the room we just left there's
		// a 50/50 chance we'll stay put instead.  This is to
		// damp oscillations where everybody is chasing each other
		// back and forth between two rooms.
		if((l[2] == lastRoom) && (wcRand(1, 2) == 1))
			return;

		// Figure out which direction we need to head in.
		if((d = rm0.getConnectorTo(l[2], a)) == nil) return;

		// Remember where we were this turn.
		lastRoom = rm0;

		// Silence the compiler warning.
		if(d) {}

		// Move.
		//newActorAction(a, TravelVia, d);
	}
;
