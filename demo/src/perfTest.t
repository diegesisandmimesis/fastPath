#charset "us-ascii"
//
// perfTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f perfTest.t3m
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

/*
modify Room
	allDirectionsExitList(actor?, cb?) {
		local c, dst, r;

		r = new Vector(Direction.allDirections.length());

		actor = (actor ? actor : gActor);
		if(!actor) return(r);

		Direction.allDirections.forEach(function(d) {
			if((c = getTravelConnector(d, actor)) == nil)
				return;
			if(!c.isConnectorApparent(self, actor))
				return;
			if((dst = c.getDestination(self, actor)) == nil)
				return;
			if((cb != nil) && ((cb)(d, dst) != true))
				return;
			r.append(new DestInfo(d, dst, nil, nil));
		});

		return(r);
	}

	exitList(actor?, cb?) { return(allDirectionsExitList(actor, cb)); }

	destinationList(actor?, cb?) {
		local r;

		r = new Vector();
		exitList(actor, cb).forEach({ x: r.append(x.dest_) });

		return(r);
	}
;
*/

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	// Number of trials to run for each test.
	// Each trial is finding the path between two random rooms.
	count = 1000

	// Zone instances and names.  Used by the methods we use
	// for picking random rooms.
	zoneNames = static [ 'foo', 'bar', 'baz' ]
	zones = static [ fooMap, barMap, bazMap ]

	// Utility methods for measuring elapsed time.
	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(5)); }

	// Utility method to connect two rooms north to south.
	// Not for general use, this demo only.
	_connectRoom(rm0, rm1) {
		rm0.north = rm1;
		rm1.south = rm0;
		pathfinder.addEdge(rm0.name, rm1.name);
		pathfinder.addEdge(rm1.name, rm0.name);
	}

	// Connect the two PRNG maps, last room of map0 to 1st room of map1.
	_connectMaps(map0, map1) {
		_connectRoom(map0._getRoom(map0._mapSize), map1._getRoom(1));
	}

	// Connect the individual PRNG map segments.
	tweakMap() {
		forEachInstance(Room, { x: x.fastPathID = x.name });
		_connectMaps(fooMap, barMap);
		_connectMaps(barMap, bazMap);
	}

	// Time how long it takes to create the pathfinding cache.
	timeCache() {
		local ts;

		pathfinder.clearNextHopCache();
		t3RunGC();
		ts = getTimestamp();
		pathfinder.createNextHopCache();
		"Creating cache took <<toString(getInterval(ts))>> seconds.\n ";
	}

	// Run (and time) tests.
	// First arg is a label for the results, second arg is the
	// test callback.
	// Return value is the interval.
	runTest(lbl, cb) {
		local i, r, ts;

		// Get the time at the start of the test.
		ts = getTimestamp();

		// Invoke the callback count times.
		for(i = 0; i < count; i++)
			cb(i);

		// Get the interval since the start of the test.
		r = getInterval(ts);

		// Log the results.
		"Computing <<toString(count)>> paths via <<lbl>>
			took <<toString(r)>> seconds.\n ";

		// Return the interval.
		return(r);
	}

	// Returns a random room instance.
	// This relies on the SimpleRandomMap._getRoom() method provided
	// by the simpleRandomMap module.
	pickRandomRoom() {
		local z;

		z = zones[rand(zones.length) + 1];
		return(z._getRoom(rand(z._mapSize) + 1));
	}

	newGame() {
		local t0, t1;

		// Connect the blocks of PRNG map.
		tweakMap();

		// Report how long it takes to build the next hop cache.
		timeCache();

		// Compute the path repeatedly, choosing random
		// endpoints.  This test uses the pathfinder provided
		// by this module.
		t0 = runTest('RoomPathfinder.findPath()', function(n) {
			local l, rm0, rm1;

			rm0 = pickRandomRoom();
			rm1 = pickRandomRoom();
			l = pathfinder.findPath(rm0, rm1);
			if(!pathfinder.testPath(rm0, rm1, l))
				"ERROR: pathfinding failed\n ";
		});

		// Compute the path repeatedly, choosing random
		// endpoints.  This test uses the adv3 pathfinder
		// from extensions/pathfind.t .
		t1 = runTest('roomPathfinder.findPath()', function(n) {
			local l, rm0, rm1;

			rm0 = pickRandomRoom();
			rm1 = pickRandomRoom();
			l = roomPathFinder.findPath(me, rm0, rm1);
			if(l == nil) "ERROR: no path\n ";
		});

		// Figure out how much faster the module is compared to
		// the stock pathfinder.
		t0 = new BigNumber(t0);
		t1 = new BigNumber(t1);
		"Speedup of <<toString(((t1 / t0)).roundToDecimal(3))>>\n ";
	}
;

// We have to define at least one Actor, as connector passability is
// per-Actor.
me: Person;

pathfinder: RoomPathfinder;

modify SimpleRandomMapRoom
	fastPathID = (name)
;

// Three room classes for the three map generators.  All we care about
// here is assigning each class a unique-ish zone ID, so all the rooms
// in each PRNG map block will be in the same zone.
class RoomFoo: SimpleRandomMapRoom fastPathZone = 'foo';
class RoomBar: SimpleRandomMapRoom fastPathZone = 'bar';
class RoomBaz: SimpleRandomMapRoom fastPathZone = 'baz';

// Three random map generator instances.
fooMap: SimpleRandomMapGenerator
	movePlayer = nil		// don't try to place player in map
	roomClass = RoomFoo		// class for created Room instances
	roomBaseName = 'fooroom'	// room names will be this plus a number
;
barMap: SimpleRandomMapGenerator
	movePlayer = nil
	roomClass = RoomBar
	roomBaseName = 'barroom'
;
bazMap: SimpleRandomMapGenerator
	movePlayer = nil
	roomClass = RoomBaz
	roomBaseName = 'bazroom'
;
