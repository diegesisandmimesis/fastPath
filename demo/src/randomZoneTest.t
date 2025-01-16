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

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(3)); }

	newGame() {
		pathfinder.createNextHopCache();
		local l = pathfinder.findFastPath('room1', 'room100');
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

pathfinder: RoomPathfinder;

map: SimpleRandomMapGenerator
	movePlayer = nil
;
