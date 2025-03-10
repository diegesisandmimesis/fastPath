#charset "us-ascii"
//
// updateTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
//
// This demo is intended to be a minimalistic test for updating cached
// pathfinding data.  It provides a gameworld consisting of six rooms,
// with room "Foo 1" being the "start" location and "Bar 1" being the
// "destination" location.  The rooms are connected by two possible
// paths, each containing a door.  Only one door is ever open at a time,
// meaning there's only ever one valid path:  either [ foo1, foo2, bar2,
// bar1 ] or [ foo1, foo3, bar3, bar1 ].
//
// When the demo starts NEITHER door is open, meaning there is no
// path between Foo 1 and Bar 1.
//
// The demo implements several bespoke actions:
//
//	> PATHFIND
//		Prints the path between room Foo 1 and room Bar 1 using
//		the fastPath pathfinder.
//
//	> ADV3 PATHFIND
//		Prints the path between room Foo 1 and room Bar 1 using
//		adv3's roomPathFinder.findPath().
//
//	> TOGGLE PATH
//		Open one door and close and lock the other.
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

versionInfo: GameID
	inlineCommand(cmd) { "<b>&gt;<<toString(cmd).toUpper()>></b>"; }
	printCommand(cmd) { "<.p>\n\t<<inlineCommand(cmd)>><.p> "; }
	showAbout() {
		"\n ";
		"This is an interactive test for updating the pathfinding
		cache.  The gameworld consists of six rooms:  <q>Foo 1</q>
		is the start room, with <q>Foo 2</q> to the north and
		<q>Foo 3</q> to the south.  There's a door east from
		<q>Foo2</q> to <q>Bar2</q> and a door east from <q>Foo3</q>
		to <q>Bar3</q>  Finally there's a <q>Bar1</q> south of
		<q>Bar2</q> and north of <q>Bar3</q>.
		<.p>
		Only one of the doors between the <q>foo</q> rooms and the
		<q>bar</q> rooms is open at a time, except at the start
		when <b>NEITHER</b> door is open.  Meaning there's
		no path between <q>Foo 1</q> and <q>Bar 1</q> at the start.
		<.p>
		Some commands available in the demo:
		<<printCommand('pathfind')>>
		\n\t\tPrints the path between <q>Foo 1</q> and <q>Bar 1</q>
		\n\t\tusing the fastPath pathfinder.
		<<printCommand('adv3 pathfind')>>
		\n\t\tPrints the path between <q>Foo 1</q> and <q>Bar 1</q>
		\n\t\tusing adv3's roomPathFinder.findPath().
		<<printCommand('toggle path')>>
		\n\t\tOpen one of the doors, closing and locking the other.
		\n<.p>\n ";
	}
;
gameMain: GameMainDef
	initialPlayerChar = me

	// Flag used to keep track of what state the doors are in.
	pathToggle = nil

	newGame() {
		intro();
		inherited();
	}

	intro() {
	}
;

// The >PATHFIND action, which uses the fastPath pathfinder.
DefineIAction(Pathfind)
	execAction() {
		local l;

		// Get the path, complaining if pathfinding fails.
		l = pathfinder.findPath(foo1, bar1);
		if(l.length < 2) {
			"\nNo path.\n ";
			return;
		}

		// Output the room names.
		"\nfastPath pathfinder says:\n ";
		l.forEach(function(o) {
			"\n\t<<o.name>>\n ";
		});
	}
;
VerbRule(Pathfind) 'pathfind'
	: PathfindAction verbPhrase = 'pathfind/pathfinding';

// Copy of >PATHFIND that uses adv3's roomPathfinder.findPath().
DefineIAction(AdvPathfind)
	execAction() {
		local l;

		// roomPathfinder.findPath() returns nil (instead of
		// an empty list) on failure, so we check for that.
		l = roomPathFinder.findPath(me, foo1, bar1);
		if((l == nil) || (l.length < 2)) {
			"\nNo path.\n ";
			return;
		}

		"\nAdv3 pathfinder says:\n ";
		l.forEach(function(o) {
			"\n\t<<o.name>>\n ";
		});
	}
;
VerbRule(AdvPathfind) ( 'adv' | 'adv3' ) 'pathfind'
	: AdvPathfindAction verbPhrase = 'adv3 pathfind/pathfinding';

// Resets the fastPath pathfinder.  Shouldn't be needed, only here for
// testing.
DefineIAction(ResetPath)
	execAction() {
		"\nResetting pathfinder.\n ";
		pathfinder.resetFastPath();
	}
;
VerbRule(ResetPath) 'reset' ('path' | 'pathfinder')
	: ResetPathAction verbPhrase = 'reset/resetting pathfinding';

// Closes and locks one door and opens and unlocks the other.
DefineIAction(TogglePath)
	execAction() {
		gameMain.pathToggle = !gameMain.pathToggle;
		if(gameMain.pathToggle) {
			door1A.makeOpen(true);
			door1A.makeLocked(nil);

			door2A.makeOpen(nil);
			door2A.makeLocked(true);

			"\nOpening door one.\n ";
		} else {
			door2A.makeOpen(true);
			door2A.makeLocked(nil);

			door1A.makeOpen(nil);
			door1A.makeLocked(true);

			"\nOpening door two.\n ";
		}
	}
;
VerbRule(TogglePath) 'toggle' ('path' | 'paths')
	: TogglePathAction verbPhrase = 'toggle/toggling paths';

// Declare a generic RoomPathfinder instances.
pathfinder: RoomPathfinder;

// Class for our rooms.  Just provides a dumb default description.
class DemoRoom: Room desc = "This is room <<name>>. ";

// Classes for our two "zones" (of three rooms each).
class FooRoom: DemoRoom 'Foo' fastPathZone = 'foo';
class BarRoom: DemoRoom 'Bar' fastPathZone = 'bar';

// Class for our doors.
class DemoDoor: IndirectLockable, Door 'door' 'door';

// Our simple six-room gameworld.
// First the "foo" zone.
foo1: FooRoom 'foo1' north = foo2 south = foo3;
+me: Person;
foo2: FooRoom 'foo2' south = foo1 east = door1A;
+door1A: DemoDoor;
foo3: FooRoom 'foo3' north = foo1 east = door2A;
+door2A: DemoDoor;

// Now the "bar" zone.
bar1: BarRoom 'bar1' north = bar2 south = bar3;
bar2: BarRoom 'bar2' south = bar1 west = door1B;
+door1B: DemoDoor masterObject = door1A;
bar3: BarRoom 'bar3' north = bar1 west = door2B;
+door2B: DemoDoor masterObject = door2A;
