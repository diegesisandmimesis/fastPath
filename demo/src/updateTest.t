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

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	getTimestamp() { return(new Date()); }
	getInterval(d) { return(((new Date() - d) * 86400).roundToDecimal(3)); }

	pathToggle = nil

	newGame() {
		inherited();
	}
;

DefineIAction(Pathfind)
	execAction() {
		local l;

		l = pathfinder.findPath(foo1, bar1);
		if(l.length < 2) {
			"\nNo path.\n ";
			return;
		}
		"\nPath:\n ";
		l.forEach(function(o) {
			"\n\t<<o.name>>\n ";
		});
	}
;
VerbRule(Pathfind) 'pathfind'
	: PathfindAction verbPhrase = 'pathfind/pathfinding';

DefineIAction(ResetPath)
	execAction() {
		"\nResetting pathfinder.\n ";
		pathfinder.resetFastPath();
	}
;
VerbRule(ResetPath) 'reset' ('path' | 'pathfinder')
	: ResetPathAction verbPhrase = 'reset/resetting pathfinding';

DefineIAction(TogglePath)
	execAction() {
		gameMain.pathToggle = !gameMain.pathToggle;
		if(gameMain.pathToggle) {
			door1A.makeLocked(nil);
			door1A.makeOpen(true);

			door2A.makeLocked(true);
			door2A.makeOpen(nil);

			"\nOpening door one.\n ";
		} else {
			door2A.makeLocked(nil);
			door2A.makeOpen(true);

			door1A.makeLocked(true);
			door1A.makeOpen(nil);

			"\nOpening door two.\n ";
		}

		pathfinder.updatePathfinder(door1A);
		pathfinder.updatePathfinder(door1B);
		pathfinder.updatePathfinder(door2A);
		pathfinder.updatePathfinder(door2B);
	}
;
VerbRule(TogglePath) 'toggle' ('path' | 'paths')
	: TogglePathAction verbPhrase = 'toggle/toggling paths';

pathfinder: RoomPathfinder;

class DemoRoom: Room
	desc = "This is room <<name>>. "
;

class FooRoom: DemoRoom 'Foo' fastPathZone = 'foo';
class BarRoom: DemoRoom 'Bar' fastPathZone = 'bar';

class DemoDoor: IndirectLockable, Door 'door' 'door';

foo1: FooRoom 'foo1' north = foo2 south = foo3;
+me: Person;
foo2: FooRoom 'foo2' south = foo1 east = door1A;
+door1A: DemoDoor;
foo3: FooRoom 'foo3' north = foo1 east = door2A;
+door2A: DemoDoor;

bar1: BarRoom 'bar1' north = bar2 south = bar3;
bar2: BarRoom 'bar2' south = bar1 west = door1B;
+door1B: DemoDoor masterObject = door1A;
bar3: BarRoom 'bar3' north = bar1 west = door2B;
+door2B: DemoDoor masterObject = door2A;

modify RoomPathfinder
	executeTurn() {
		aioSay('\nflush queue\n ');
		inherited();
	}
;
