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

#include <date.h>
#include <bignum.h>

#include "fastPath.h"

#include "simpleRandomMap.h"
#ifndef SIMPLE_RANDOM_MAP_H
#error "This demo requires the simpleRandomMap module. "
#endif // SIMPLE_RANDOM_MAP_H

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

	actors = perInstance(new Vector())

	// For caching which room has the most actors in it.
	_mainRoomTimestamp = nil
	_mainRoom = nil

	// Returns a random room instance.
	// This relies on the SimpleRandomMap._getRoom() method provided
	// by the simpleRandomMap module.
	pickRandomRoom() { return(map._getRoom(rand(map._mapSize) + 1)); }

	newGame() {
		local a, g, i, rm;

		// Create a new actor for each room in the random map.
		for(i = 1; i <= map._mapSize; i++) {
			// Pick a random room.
			rm = map._getRoom(rand(map._mapSize) + 1);

			a = new DemoActor();	// create new actor
			a.initializeActor();	// IMPORTANT:  adv3 needs this
			a.setActorNumber(i);	// set the actor number
			a.moveInto(rm);		// move to random room

			g = new DemoAgenda();	// create the travel agenda
			a.addToAgenda(g);
			g.location = a;		// IMPORTANT: for getActor()

			actors.append(a);	// bookkeeping
		}

		inherited();
	}

	// Figure out which room has the most actors in it.
	getMainRoom() {
		local i, max, mrm, rm, ts, v;

		ts = libGlobal.totalTurns;
		if((_mainRoomTimestamp == ts) && (_mainRoom != nil))
			return(_mainRoom);

		_mainRoomTimestamp = ts;
		
		max = 0;
		for(i = 1; i <= map._mapSize; i++) {
			v = 0;
			if((rm = map._getRoom(i)) == nil) continue;

			rm.contents.forEach(function(o) {
				if(!o.ofKind(DemoActor)) return;
				v += 1;
			});

			if(v > max) {
				max = v;
				mrm = rm;
			}
		}

		_mainRoom = mrm;

		return(_mainRoom);
	}
;

me: Person;

//class DemoActor: Person 'alice' 'Alice'
class DemoActor: Person
	desc = "She looks like the <<spellIntOrdinal(actorNumber)>> person
		you'd turn to in a problem. "
	isHer = true
	isProperName = true

	actorNumber = nil

	target = nil

	setActorNumber(n) {
		actorNumber = n;
		name = _demoNames[n];
		cmdDict.addWord(self, _demoNames[n].toLower(), &noun);
	}
;

class DemoAgenda: AgendaItem
	initiallyActive = true
	isReady = true

	lastRoom = nil

	targetActor = nil

	// Pick a random actor and make them the target.
	setTarget() {
		local a, i;

		if((a = getActor()) == nil) return(nil);

		i = nil;

		// Make sure we don't pick ourselves.
		while((i == nil) || (i == a.actorNumber))
			i = rand(gameMain.actors.length()) + 1;

		targetActor = gameMain.actors[i];

		return(true);
	}

	// Get the room containing our target.
	getTargetRoom() {
		if(targetActor == nil) return(nil);
		return(targetActor.getOutermostRoom());
	}

	invokeItem() {
		local a, d, l, rm0, rm1;

		// Make sure we have an actor and they're in a room.
		if((a = getActor()) == nil) return;
		if((rm0 = a.getOutermostRoom()) == nil) return;

		// If we don't have a target, get one.
		if(targetActor == nil) setTarget();

		// Make sure the target is valid and in a room.
		if((rm1 = getTargetRoom()) == nil) return;

		// If we're in the target room, nothing to do.
		if(rm0 == rm1) return;

		l = pathfinder.findPath(rm0, rm1);
		if(l.length < 2) return;

		// If our current destination is the room we occupied
		// last turn, give it a 50/50 chance to stay put.  This
		// is to damp occilations where everybody is chasing
		// each other back and forth between the same two rooms.
		if((l[2] == lastRoom) && ((rand(10) + 1) < 5)) {
			lastRoom = rm0;
			return;
		}

		if((d = rm0.getConnectorTo(l[2], a)) == nil) return;

		// Remember the room we occupied this turn.
		lastRoom = rm0;

		newActorAction(a, TravelVia, d);
	}
;

class DemoRoom: SimpleRandomMapRoom
	turnTimestamp = nil
	_mainRoom = nil

	desc = "This is a simple random room.  Its coordinates are
		<<getCoords()>>.
		<.p>
		The room with the most actors is currently <<mainRoom()>>.
		To reach it, go <<directionToMainRoom()>>. "

	// Wrapper with error handling for gameMain.getMainRoom().
	mainRoom() {
		local rm;

		if((rm = gameMain.getMainRoom()) == nil) return('unknown');
		return(rm.name);
	}

	// Returns the name of the direction that leads to the room with
	// the most mobs (from the point of view of the me actor).
	directionToMainRoom() {
		local c, l, rm0, rm1;

		if((rm1 = gameMain.getMainRoom()) == nil)
			return('to errorland');
		rm0 = me.getOutermostRoom();
		if(rm0 == rm1) return('nowhere');
		l = pathfinder.findPath(rm0, rm1);
		if(l.length < 2) return('nowhere fast');
		if((c = rm0.getDirTo(l[2], me)) == nil)
			return('into the void');
		return(toString(c.dirProp));
	}
;

pathfinder: RoomPathfinder;
map: SimpleRandomMapGenerator roomClass = DemoRoom;
