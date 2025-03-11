#charset "us-ascii"
//
// activeTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f activeTest.t3m
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

modify Room
	// Returns the connector from this room to the given room, for the
	// given actor.
	getConnectorTo(rm, actor) {
		local c, dst, r;

		Direction.allDirections.forEach(function(d) {
			if((c = getTravelConnector(d, actor)) == nil) return;
			if(!c.isConnectorApparent(self, actor)) return;
			if((dst = c.getDestination(self, actor)) == nil) return;
			if(dst != rm) return;
			r = c;
		});

		return(r);
	}

	// Returns the direction that leads to the given room, for the given
	// actor.
	getDirTo(rm, actor) {
		local c, dst, r;

		Direction.allDirections.forEach(function(d) {
			if((c = getTravelConnector(d, actor)) == nil) return;
			if(!c.isConnectorApparent(self, actor)) return;
			if((dst = c.getDestination(self, actor)) == nil) return;
			if(dst != rm) return;
			r = d;
		});

		return(r);
	}
;

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me


	toggleDoors() {
			//d0.makeLocked(true);
			//pathfinder.updatePathfinder(d0);
	}

	newGame() {
		pathfinder.resetFastPath();
		inherited();
	}
;

westRoom: Room 'West Room' "This is the west room. "
	fastPathZone = 'west'
	east = westDoor
;
+westDoor: IndirectLockable, AutoClosingDoor 'door' 'door';
+me: Person;
+alice: Person 'Alice' 'Alice'
	"She looks like the first person you'd turn to in a problem. "
	isHer = true
	isProperName = true
;
++AgendaItem
	initiallyActive = true
	isReady = true

	targetActor = bob	// actor we're looking for

	getTargetRoom() {
		if(targetActor == nil) return(nil);
		return(targetActor.getOutermostRoom());
	}

	invokeItem() {
		local a, d, l, rm0, rm1;

		//if((rand(100) + 1) <= 25) return;

		if((a = getActor()) == nil) return;
		if((rm0 = a.getOutermostRoom()) == nil) return;

		if(targetActor == nil) return;

		if((rm1 = getTargetRoom()) == nil) return;

		if(rm0 == rm1) return;

		l = pathfinder.findPath(rm0, rm1);
		if(l.length < 2) return;

		if((d = rm0.getConnectorTo(l[2], a)) == nil) return;

		newActorAction(a, TravelVia, d);
	}
;

eastRoom: Room 'East Room' "This is the east room. "
	fastPathZone = 'east'
	west = eastDoor
;
+eastDoor: IndirectLockable, AutoClosingDoor 'door' 'door'
	masterObject = westDoor
;
+bob: Person 'Bob' 'Bob' "He looks like Robert, only shorter. "
	isHim = true
	isProperName = true
;

pathfinder: RoomPathfinder;

DefineIAction(Rezrov)
	execAction() {
		if(!westDoor.isLocked()) {
			reportFailure('Foop, the door is already unlocked. ');
			return;
		}
		westDoor.makeLocked(nil);
		westDoor.makeOpen(nil);
		defaultReport('Poof, the door is unlocked. ');
	}
;
VerbRule(Rezrov) 'rezrov' : RezrovAction verbPhrase = 'rezrov/rezroving';

DefineIAction(Vorzer)
	execAction() {
		if(westDoor.isLocked()) {
			reportFailure('Polp, the door is already locked. ');
			return;
		}
		westDoor.makeLocked(true);
		westDoor.makeOpen(true);
		defaultReport('Plop, the door is locked. ');
	}
;
VerbRule(Vorzer) 'vorzer' : VorzerAction verbPhrase = 'vorzer/vorzering';

DefineIAction(Foozle)
	execAction() {
		pathfinder.log();
	}
;
VerbRule(Foozle) 'foozle' : FoozleAction verbPhrase = 'foozle/foozling';

