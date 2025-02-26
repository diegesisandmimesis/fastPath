#charset "us-ascii"
//
// activeTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This demo is intended to be a performance test for the fastPath library.
// It features four hundred rooms and four hundred actors.
//
// The map consists of four zones, each of which is a 10x10 random maze.
// The rooms in each zone are numbered from 1 to 100, with 1 in the southwest
// corner, 10 in the southeast corner, 91 in the northwest corner, and
// 100 in the northeast corner.
//
// The zones are laid out in a 2x2 grid, and their names indicate their
// position:  nw, ne, sw, and se.
//
// Each zone is connected to each adjacent zone by two doors in the corners
// of the zone boundary.  For example the nw zone is connected to the ne
// zone with an east-west door in nw room 100 that connects to ne room 91, and
// an east-west door in the nw room 10 that connects to the ne room 1.
//
// The game logic works such that only one of each pair of doors connecting
// two zones is open at any time.  The demo includes a daemon that periodically
// toggles the doors, closing one of each pair and opening the other (meaning
// that the zones remain reachable but the paths change).
//
// Each actor picks a random other actor they want to reach.  Each turn
// every actor evaluates an agenda that (probably) causes them to move
// toward their chosen other actor.
//
// The room description in every room reports the room that currently
// has the most actors in it, and the move the player should take to
// reach it.
//
// There's also an >ACTOR MAP command that displays an ASCII art map of
// where the actors are, a '.' indicating a room with no actors, a
// number between 0 and 9 indicating the size of the room's population (the
// number being the number of actors in the room divided by 40, capped at
// 9--so 0 is 1 to 39 actors, 1 is 40 to 79, and so on).  The player's
// position is marked by a '@'.
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
	// Boolean.  Setting this to nil will cause the demo to
	// use the stock adv3 pathfinder.  For performance testing.
	useFastPath = true

	// Standard adv3.  The default player character.
	initialPlayerChar = me

	// Array for all the actors.
	// Added in order, but we don't really care about the order.
	actors = perInstance(new Vector())

	// Array for all the doors.
	// Added in pairs of pairs.  Each "logical" door in a T3
	// game is represented by two objects:  a "main" door object and
	// an "other side of the door" object, one for each of the
	// two rooms the door connects.
	// The door list starts with index 1 being the first "main" door
	// and index 2 being its "other side", with this pattern
	// continuing for the rest of the array.
	// Also, as part of the design of the demo whenever two zones
	// are connected to each other they are connected by two doors.
	// If the zones are arranged north-south then the doors are
	// in the northwest and northeast corner of the southern zone
	// and the southwest and southeast corner of the northern zone.
	// The way the game logic works, only one of these doors will
	// be open at a time.
	doorList = perInstance(new Vector())

	// Arrays of our zones.  Used by various methods as lookups.
	zoneNames = static [ 'ne', 'nw', 'se', 'sw' ]
	zones = static [ neMap, nwMap, seMap, swMap ]

	doorDaemon = nil

	// For caching which room has the most actors in it.
	_mainRoomTimestamp = nil
	_mainRoom = nil

	// Returns a random room instance.
	// This relies on the SimpleRandomMap._getRoom() method provided
	// by the simpleRandomMap module.
	pickRandomRoom() {
		local z;
		z = zones[rand(zones.length) + 1];
		return(z._getRoom(rand(z._mapSize) + 1));
	}

	_createDoorPair(rm0, prop0, rm1, prop1) {
		local d0, d1;

		d0 = new DemoDoor();
		d1 = new DemoDoor();

		d1.masterObject = d0;

		d0.moveInto(rm0);
		d1.moveInto(rm1);

		d0.initializeThing();
		d1.initializeThing();

		d0.makeLocked(nil);

		doorList.append(d0);
		doorList.append(d1);

		rm0.(prop0) = d0;
		rm1.(prop1) = d1;
	}

	_connectRoomNorthSouth(rm0, rm1) {
		_createDoorPair(rm0, &north, rm1, &south);

		pathfinder.addEdge(rm0.fastPathID, rm1.fastPathID);
		pathfinder.addEdge(rm1.fastPathID, rm0.fastPathID);
	}

	_connectRoomEastWest(rm0, rm1) {
		_createDoorPair(rm0, &east, rm1, &west);

		pathfinder.addEdge(rm0.fastPathID, rm1.fastPathID);
		pathfinder.addEdge(rm1.fastPathID, rm0.fastPathID);
	}

	_connectMapsNorthSouth(map0, map1) {
		_connectRoomNorthSouth(
			map0._getRoom(map0._mapSize - map0.mapWidth + 1),
			map1._getRoom(1)
		);
		_connectRoomNorthSouth(
			map0._getRoom(map0._mapSize),
			map1._getRoom(map1.mapWidth)
		);
	}

	_connectMapsEastWest(map0, map1) {
		_connectRoomEastWest(
			map0._getRoom(map0.mapWidth),
			map1._getRoom(1)
		);
		_connectRoomEastWest(
			map0._getRoom(map0._mapSize),
			map1._getRoom(map1._mapSize - map1.mapWidth + 1)
		);
	}

	tweakMap() {
		_connectMapsNorthSouth(seMap, neMap);
		_connectMapsNorthSouth(swMap, nwMap);
		_connectMapsEastWest(nwMap, neMap);
		_connectMapsEastWest(swMap, seMap);
	}

	// Wrapper around pathfinding method.
	// We do this so it's easier to swap methods for a/b testing.
	findPath(a, rm0, rm1) {
		if(useFastPath == true)
			return(pathfinder.findPath(rm0, rm1));
		else
			return(roomPathFinder.findPath(a, rm0, rm1));
	}

	updatePathfinder(v) {
		if(useFastPath == true)
			pathfinder.updatePathfinder(v);
	}

	timeCache() {
		local ts;

		ts = getTimestamp();
		pathfinder.resetFastPath();
		aioSay('\ncache creation took <<toString(getInterval(ts))>>
			seconds. \n');
	}

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(5)); }

	toggleDoors() {
		local d0, d1, i;

		for(i = 1; i <= doorList.length; i += 4) {
			if((rand(100) + 1) < 75) continue;
			if((rand(100) + 1) < 50) {
				d0 = i;
				d1 = i + 2;
			} else {
				d0 = i + 2;
				d1 = i;
			}
			_toggleDoor(d0, true);
			_toggleDoor(d1, nil);
		}
	}

	_toggleDoor(idx, st) {
		local d0, d1;

		d0 = doorList[idx];
		d1 = doorList[idx + 1];

		d0.makeLocked(st);
		d0.makeOpen(st);

		gameMain.updatePathfinder(d0);
		gameMain.updatePathfinder(d1);
	}

	newGame() {
		tweakMap();

		timeCache();

		zones.forEach({ x: _addActors(x) });

		doorDaemon = new Daemon(self, &toggleDoors, 1);

		inherited();
	}

	_addActors(z) {
		local a, g, i, rm;

		for(i = 1; i <= z._mapSize; i++) {
			rm = z._getRoom(i);

			a = new DemoActor();	// create new actor
			a.initializeActor();	// IMPORTANT:  adv3 needs this
			a.setActorNumber(i, z);	// set the actor number
			a.moveInto(rm);		// move to random room

			g = new DemoAgenda();	// create the travel agenda
			a.addToAgenda(g);
			g.location = a;		// IMPORTANT: for getActor()
			a._demoAgenda = g;

			actors.append(a);	// bookkeeping
		}
	}

	// Figure out which room has the most actors in it.
	getMainRoom() {
		local max, mrm, ts, v;

		ts = libGlobal.totalTurns;
		if((_mainRoomTimestamp == ts) && (_mainRoom != nil))
			return(_mainRoom);

		_mainRoomTimestamp = ts;
		
		max = 0;
		forEachInstance(Room, function(rm) {
			v = 0;
			rm.contents.forEach(function(o) {
				if(!o.ofKind(DemoActor)) return;
				v += 1;
			});

			if(v > max) {
				max = v;
				mrm = rm;
			}
		});

		_mainRoom = mrm;

		return(_mainRoom);
	}
;

me: Person
	executeTurn() {
		inherited();
		demoAfter.ts = gameMain.getTimestamp();
	}
;

class DemoActor: Person
	desc = "She looks like the <<spellIntOrdinal(actorNumber)>> person
		you'd turn to in a problem. "
	isHer = true
	isProperName = true

	actorNumber = nil	// number from 1 to 100

	_demoAgenda = nil	// Pointer to the pathfinding agenda

	// Set our name based on our number.
	setActorNumber(n, z) {
		actorNumber = n;
		name = _demoNames[n] + ' ' + z.name;
		cmdDict.addWord(self, _demoNames[n].toLower(), &noun);
	}
;

// Agenda to seek out a randomly-selected actor.
class DemoAgenda: AgendaItem
	initiallyActive = true
	isReady = true

	lastRoom = nil		// previous room we were in
	targetActor = nil	// actor we're looking for

	// Pick a random actor to look for.
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

	// Get the room containing the actor we're looking for.
	getTargetRoom() {
		if(targetActor == nil) return(nil);
		return(targetActor.getOutermostRoom());
	}

	invokeItem() {
		local a, d, l, rm0, rm1;

		// Base 25% chance of doing nothing any turn.
		if((rand(100) + 1) <= 25) return;

		// Make sure we have an actor and they're in a room.
		if((a = getActor()) == nil) return;
		if((rm0 = a.getOutermostRoom()) == nil) return;

		// If we don't have a target, get one.
		if(targetActor == nil) setTarget();

		// Make sure the target is valid and in a room.
		if((rm1 = getTargetRoom()) == nil) return;

		// If we're in the target room, nothing to do.
		if(rm0 == rm1) return;

		// Get the path from our current location to our
		// target's current location.
		l = gameMain.findPath(a, rm0, rm1);
		if(l.length < 2) return;
/*
aioSay('\n==<<getActor().name>>==\n ');
aioSay('\n\ttarget = <<targetActor.name>>==\n ');
aioSay('\n\tfrom = <<rm0.name>>\n ');
aioSay('\n\tto = <<rm1.name>>\n ');
l.forEach(function(o) {
	aioSay('\n\t\t<<o.fastPathID>>\n ');
});
aioSay('\n==<<getActor().name>>==\n ');
*/

		// If our current destination is the room we came from,
		// give it a 50/50 chance to stay put.  This is to damp
		// occilations where everybody is chasing
		// each other back and forth between the same two rooms.
		if((l[2] == lastRoom) && ((rand(10) + 1) <= 5))
			return;

		if((d = rm0.getConnectorTo(l[2], a)) == nil) return;

		// Remember the room we occupied this turn.
		lastRoom = rm0;

		newActorAction(a, TravelVia, d);
	}
;

class DemoRoom: SimpleRandomMapRoom
	turnTimestamp = nil
	_mainRoom = nil

	desc = "This is a room in the <<toString(fastPathZone.toUpper())>>
		zone.  Its coordinates are <<getCoords()>>.
		<.p>
		The room with the most actors is currently <<mainRoom()>>.
		To reach it, go <<directionToMainRoom()>>. "

	// Wrapper with error handling for gameMain.getMainRoom().
	mainRoom() {
		local rm;

		if((rm = gameMain.getMainRoom()) == nil) return('unknown');
		return(rm.name + ', zone ' + rm.fastPathZone.toUpper());
	}

	// Returns the name of the direction that leads to the room with
	// the most mobs (from the point of view of the me actor).
	directionToMainRoom() {
		local c, l, rm0, rm1;

		if((rm1 = gameMain.getMainRoom()) == nil)
			return('to errorland');
		rm0 = me.getOutermostRoom();
		if(rm0 == rm1) return('nowhere');
		l = gameMain.findPath(me, rm0, rm1);
		if(l.length < 2) return('nowhere fast');
		if((c = rm0.getDirTo(l[2], me)) == nil)
			return('into the void');
		return(toString(c.dirProp));
	}

;

pathfinder: RoomPathfinder;

// Action that displays a crude ASCII map of the population density
// of the rooms:  a "." represents an empty room and the numerals 0-9
// represent 1-10, 11-20, 21-30, and so on mobs.  The player isn't
// included in the count.
DefineIAction(ActorMap)
	execAction() {
		local i, j, l, tmp, y, zones;

		//gameMain.timeCache();

		zones = [ [ nwMap, neMap ], [ swMap, seMap ] ];

		tmp = new StringBuffer();

		for(i = 1; i <= zones.length; i++) {
			l = zones[i];
			for(y = l[1].mapWidth - 1; y >= 0; y--) {
				for(j = 1; j <= l.length; j++) {
					tmp.append(getMapLine(y, l[j]));
				}
				tmp.append('\n ');
			}
		}
		"\n<<toString(tmp)>>\n ";
	}

	getMapLine(y, zone) {
		local x, txt;

		txt = new StringBuffer();
		for(x = 1; x <= zone.mapWidth; x++) {
			txt.append(getMapTile(x, y, zone));
		}

		return(toString(txt));
	}

	getMapTile(x, y, zone) {
		local d, idx, n, rm;

		idx = (y * zone.mapWidth) + x;
		if((rm = zone._getRoom(idx)) == nil) {
			aioSay('\nERROR:  nil room, <<toString(idx)>> in
				zone <<toString(zone)>>\n ');
			return('x');
		}

		if(rm == gameMain.initialPlayerChar.location)
			return('@');

		n = 0;
		rm.contents.forEach(function(o) {
			if(!o.ofKind(DemoActor)) return;
			n += 1;
		});

		if(n == 0)
			return('.');

		d = gameMain.actors.length() / 10;
		n /= d;

		if(n > 9)
			n = 9;


		return(toString(n));
	}
;
VerbRule(ActorMap)
	'actor' 'map' : ActorMapAction
	verbPhrase = 'map/mapping actors'
;


DefineTAction(DebugActor);
VerbRule(DebugActor)
	'debug' 'actor' singleDobj: DebugActorAction
	verbPhrase = 'debug/debugging (who)'
;

modify Thing
	dobjFor(DebugActor) { verify() { illogical('Not an actor.'); } }
;

modify Actor
	_demoAgenda = nil

	dobjFor(DebugActor) {
		verify() {
			if(_demoAgenda == nil)
				illogicalNow('No pathfinding agenda.');
		}
		action() {
			local a, l, rm0, rm1, t;

			a = _demoAgenda;

			"\n===<<toString(name)>>===\n ";
			if((t = a.targetActor) != nil)
				"\n\ttarget = <<toString(t.name)>>\n ";
			else
				"\n\tNO TARGET\n ";

			if((rm0 = location) != nil)
				"\n\tfrom = <<rm0.name>>\n ";
			else
				"\n\tNO LOCATION\n ";

			if((rm1 = a.getTargetRoom()) != nil)
				"\n\tto = <<toString(rm1.name)>>\n ";
			else
				"\n\tNO TARGET ROOM\n ";

			if((l = gameMain.findPath(l, rm0, rm1)) == nil) {
				"\n\tPATHFINDING FAILED\n ";
			} else {
				"\n\tPath:\n ";
				l.forEach(function(o) {
					"\n\t\t<<o.name>>\n ";
				});
			}

			"\n===<<toString(name)>>===\n ";
		}
	}
;



class NERoom: DemoRoom fastPathZone = 'ne';
class NWRoom: DemoRoom fastPathZone = 'nw';
class SERoom: DemoRoom fastPathZone = 'se';
class SWRoom: DemoRoom fastPathZone = 'sw';

class DemoMapGenerator: SimpleRandomMapGeneratorBraid
	mapWidth = 10
	//mapWidth = 3
;

swMap: DemoMapGenerator name = 'SouthWest' roomClass = SWRoom;
seMap: DemoMapGenerator name = 'SouthEast' roomClass = SERoom movePlayer = nil;
neMap: DemoMapGenerator name = 'NorthEast' roomClass = NERoom movePlayer = nil;
nwMap: DemoMapGenerator name = 'NorthWest' roomClass = NWRoom
	movePlayer = nil;


//class DemoDoor: IndirectLockable, AutoClosingDoor 'door' 'door';
class DemoDoor: IndirectLockable, Door 'door' 'door';


demoAfter: Schedulable
	scheduleOrder = 999
	ts = nil
	nextRunTime = (libGlobal.totalTurns)
	executeTurn() {
		"\n<.P>Turn took <<toString(gameMain.getInterval(ts))>>
			seconds. \n ";
		incNextRunTime(1);
		return(nil);
	}
;
