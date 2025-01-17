#charset "us-ascii"
//
// zoneTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f zoneTest.t3m
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

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(3)); }

	newGame() {
		pathfinder.createNextHopCache();
		local l = pathfinder.findPath('start', 'exit');
		"Path:\n ";
		if(l == nil) {
			"\n\tno path\n ";
			return;
		}
		l.forEach(function(o) {
			"\n\t<<toString(o.vertexID)>>\n ";
		});
	}
;

me: Person;

modify Room
	fastPathID = nil		// vertex ID
	fastPathZone = nil		// zone ID
	fastPathVertex = nil		// ref to vertex added automagically
;

pathfinder: FastPathPreinit
	fastPathObjectClass = Room

	fastPathGrouper(obj) {
		if(!isRoom(obj)) return(nil);
		return(new FastPathGroup(
			(obj.fastPathZone ? obj.fastPathZone : 'default'),
			(obj.fastPathID ? obj.fastPathID : obj.name)));
	}

	fastPathAddEdges(obj) {
		if(!isVertex(obj) || !isRoom(obj.data)) return;
		obj.data.destinationList(me).forEach(function(rm) {
			addEdge(obj.vertexID, rm.name);
		});
	}
;

class Foo: Room 'Foo' "This is a foo room. " fastPathZone = 'foo';
class Bar: Room 'Bar' "This is a bar room. " fastPathZone = 'bar';
startRoom: Room 'start' "This is the start room." fastPathZone = 'start'
	north = foo1;
foo1: Foo 'foo1' north = foo2 south = startRoom;
foo2: Foo 'foo2' north = foo3 south = foo1;
foo3: Foo 'foo3' north = bar1 south = foo2;
bar1: Bar 'bar1' north = bar2 south = foo3;
bar2: Bar 'bar2' north = bar1 south = bar3;
bar3: Bar 'bar3' north = exitRoom south = bar2;
exitRoom: Room 'exit' "This is the exit room." fastPathZone = 'exit'
	south = bar3;
