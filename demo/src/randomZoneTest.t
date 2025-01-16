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

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	count = 1000
	inZone = nil

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(5)); }

	newGame() {
		local i, l, rm0, rm1, ts, v0, v1;

		//pathfinder.clearNextHopCache();
		rm0 = fooMap._getRoom(100);
		rm1 = barMap._getRoom(1);
		rm0.north = rm1;
		rm1.south = rm0;
		pathfinder.addEdge(rm0.name, rm1.name);
		pathfinder.addEdge(rm1.name, rm0.name);

		rm0 = barMap._getRoom(100);
		rm1 = bazMap._getRoom(1);
		rm0.north = rm1;
		rm1.south = rm0;
		pathfinder.addEdge(rm0.name, rm1.name);
		pathfinder.addEdge(rm1.name, rm0.name);

		ts = getTimestamp();
		pathfinder.createNextHopCache();
		v0 = getInterval(ts);
		"Creating cache took <<toString(v0)>> seconds.\n ";

/*
		l = pathfinder.findPath('fooroom1', 'bazroom100');
		l.forEach(function(o) {
			"\n\t<<toString(o.vertexID)>>\n ";
		});
*/
		ts = getTimestamp();
		for(i = 0; i < count; i++) {
			rm0 = 'fooroom' + toString(rand(100) + 1);
			if(inZone)
				rm1 = 'fooroom' + toString(rand(100) + 1);
			else
				rm1 = 'bazroom' + toString(rand(100) + 1);
			l = pathfinder.findPath(rm0, rm1);
			if(l == nil) {
				"ERROR: no path\n ";
				return;
			}
		}
		v0 = getInterval(ts);
		"Computing <<toString(count)>> paths
			via RoomPathfinder.findPath()
			took <<toString(v0)>> seconds.\n ";

		ts = getTimestamp();
		for(i = 0; i < count; i++) {
			rm0 = fooMap._getRoom(rand(100) + 1);
			if(inZone)
				rm1 = fooMap._getRoom(rand(100) + 1);
			else
				rm1 = bazMap._getRoom(rand(100) + 1);
			l = roomPathFinder.findPath(me, rm0, rm1);
		}
		v1 = getInterval(ts);
		"Computing <<toString(count)>> paths
			via roomPathFinder.findPath()
			took <<toString(v1)>> seconds.\n ";

		v0 = new BigNumber(v0);
		v1 = new BigNumber(v1);
		"Speedup of <<toString(((v1 / v0)).roundToDecimal(3))>>\n ";
	}
;

me: Person;

modify Room
	fastPathID = nil		// vertex ID
	fastPathZone = nil		// zone ID
	fastPathVertex = nil		// ref to vertex added automagically
;

pathfinder: RoomPathfinder;

class RoomFoo: SimpleRandomMapRoom
	fastPathZone = 'foo'
;
class RoomBar: SimpleRandomMapRoom
	fastPathZone = 'bar'
;
class RoomBaz: SimpleRandomMapRoom
	fastPathZone = 'baz'
;

fooMap: SimpleRandomMapGenerator
	movePlayer = nil
	roomClass = RoomFoo
	roomBaseName = 'fooRoom'
;
barMap: SimpleRandomMapGenerator
	movePlayer = nil
	roomClass = RoomBar
	roomBaseName = 'barRoom'
;
bazMap: SimpleRandomMapGenerator
	movePlayer = nil
	roomClass = RoomBaz
	roomBaseName = 'bazRoom'
;
