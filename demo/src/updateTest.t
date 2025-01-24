#charset "us-ascii"
//
// updateTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f updateTest.t3m
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

/*
modify Room
	foozle(actor) {
		//local c, dst, i, lst, r;
		local c, dst, r;

		r = new Vector();

		Direction.allDirections.forEach(function(d) {
			if((c = getTravelConnector(d, actor)) == nil)
				return;
			if(!c.isConnectorApparent(self, actor))
				return;
			if((dst = c.getDestination(self, actor)) == nil)
				return;
			if(!tryIt(actor, c, dst))
				return;
			r.append(dst);
		});

		return(r);
	}
	tryIt(actor, conn, dst) {
		local r;

		try {
			newActorAction(actor, TravelVia, conn);
			if(actor.location == dst)
				r = true;
		}
		catch(Exception e) {
			return(nil);
		}
		return(r);
	}
;
*/

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(3)); }

	newGame() {
		local l;

		pathfinder.createNextHopCache();
		l = pathfinder.findPath(startRoom, exitRoom);
		"Path:\n ";
		l.forEach({ x: "\n\t<<toString(x.name)>>\n " });
		shortcutPass.makeLocked(nil);

		pathfinder.clearNextHopCache();
		pathfinder.initializeFastPath();
		pathfinder.createNextHopCache();
		l = pathfinder.findPath(startRoom, exitRoom);
		"Path:\n ";
		l.forEach({ x: "\n\t<<toString(x.name)>>\n " });
	}
;


pathfinder: RoomPathfinder;

class Foo: Room 'Foo' "This is a foo room. " fastPathZone = 'foo';
class Bar: Room 'Bar' "This is a bar room. " fastPathZone = 'bar';

startRoom: Room 'start' "This is the start room." fastPathZone = 'start'
	east = foo1;
+me: Person;

foo1: Foo 'foo1' east = foo2 west = startRoom north = shortcutBlock;
+shortcutBlock: IndirectLockable, Door 'door' 'door' masterObject = shortcutPass;
foo2: Foo 'foo2' east = foo3 west = foo1;
foo3: Foo 'foo3' east = foo4 west = foo2;
foo4: Foo 'foo4' east = foo5 west = foo3;
foo5: Foo 'foo5' east = bar1 west = foo4 north = shortcutPass;
+shortcutPass: IndirectLockable, Door 'door' 'door'
	autoUnlockOnOpen = true
	dobjFor(Unlock) {
		check() {}
		verify() {}
		action() {
			//shortcutPass.makeLocked(nil);
			inherited();
		}
	}
;

bar1: Bar 'bar1' east = bar2 west = foo5;
bar2: Bar 'bar2' east = bar3 west = bar1;
bar3: Bar 'bar3' east = exitRoom west = bar2;

exitRoom: Room 'exit' "This is the exit room." fastPathZone = 'exit'
	west = bar3;

/*
modify TravelConnector
	dobjFor(TravelVia) {
		preCond() {
			aioSay('\n===preCond 1===\n ');
			inherited();
			aioSay('\n===preCond 2===\n ');
		}
		verify() {
			aioSay('\n===verify 1===\n ');
			inherited();
			aioSay('\n===verify 2===\n ');
		}
		check() {
			aioSay('\n===check 1===\n ');
			inherited();
			aioSay('\n===check 2===\n ');
		}
		action() {
			aioSay('\n===action 1===\n ');
			inherited();
			aioSay('\n===action 2===\n ');
		}
	}
	connectorTravelPreCond() {
		local r;

		aioSay('\n==connectorTravelPreCond()==\n ');
		r = inherited();
		r.forEach(function(o) {
			aioSay('\n\t<<toString(o)>>\n ');
		});
		return(r);
	}
;
*/

class Foozle: object;
