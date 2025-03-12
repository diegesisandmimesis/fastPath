#charset "us-ascii"
//
// basicTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
//
// It implements a very small patch of very Zork-like terrain and a
// >PATHFIND action that (should) illustrate assymetric pathfinding.
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
		"\nThis demo implements a small patch of very Zork-like
		terrain that includes a (non-locking) door(-ish thing)
		and a couple of one-way passages.
		\n<.p>There's also a <<inlineCommand('pathfind')>> command
		that attempts to compute the path from the starting
		room to the deepest part of the gameworld and then
		back to the starting point.  The important point being
		that the path in and the path out should be different.
		\n<.p>This is all a bit trivial, but the point is to test that
		all you have to do is declare a RoomPathfinder instance
		and pathfinding should <q>just work</q>, and this is a
		silly but non-trivial gameworld for it to work in.
		\n<.p> ";
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
		"\nUse <<versionInfo.inlineCommand('about')>> to show
		information about this demo.
		<.p>\n ";
	}
;

// The >PATHFIND action, which uses the fastPath pathfinder.
DefineIAction(Pathfind)
	execAction() {
		sayPath(houseWest, studio);
		sayPath(studio, houseWest);
	}
	sayPath(rm0, rm1) {
		local l;

		if(!isRoom(rm0) || !isRoom(rm1)) {
			"\nsayPath() called with invalid arguments.\n ";
			return(nil);
		}
		l = pathfinder.findPath(rm0, rm1);
		if(!isCollection(l) || (l.length < 2)) {
			"\nFailed to compute path from <<rm0.name>>
				to <<rm1.name>>.\n ";
			return(nil);
		}
		"\nComputed path from <<rm0.name>> to <<rm1.name>>:\n ";
		l.forEach(function(o) {
			"\n\t<<o.name>>\n ";
		});
		return(true);
	}
;
VerbRule(Pathfind) 'pathfind'
	: PathfindAction verbPhrase = 'pathfind/pathfinding';

// Declare a generic RoomPathfinder instances.
// For our purposes we're very intentionally not modifying the behavior
// in any way--the other demos mostly have tweaks and modifications to
// do whatever the demo does.  So here we're trying to test the pathfinder
// with no modifications on a non-trivial gameworld.
pathfinder: RoomPathfinder;

houseWest: OutdoorRoom 'West of House'
	"This is a mildly infringing field west of a white house,
	with a boarded front door. "
	north = houseNorth
	south = houseSouth
	east: FakeConnector { "The door is not even implemented. " }
	west: FakeConnector { "The forest seems twisty and confusing in
		ways the developer did not find convenient to program. " }
;
+field: Decoration '(mildly) (infringing) field' 'field'
	"It's like a mildly infringing ring, but it also has a
		multiplicative inverse. "
	soundDesc = "You hear a milding infringing ring in your ears.
		It has a multiplicative inverse. "
;
+Decoration '(mildly) (infringing) ring' 'ring'
	"It's like a mildly infringing group, but with an associative
		and distributive operator. "
	soundDesc = "You hear a milding infringing group in your ears.
		It has an associative and distributed operator. "
;
+Decoration '(abelian) (albanian) (mildly) (infringing) group' 'group'
	"It's an abelian group, which means it hails from the coast
		of the Adriatic. "
;
+Unthing 'adriatic' 'Adriatic'
	'It\'s not here, it\'s in the Balkans. '
;
+Decoration '(associative) (distributive) operator'
	'associative and distributive operator'
	"You try to reach the operator but you can't get a ring tone.
	<.p>Ring tone.  That's a math joke. "
	soundDesc = "It sounds exactly like something you can't hear. "
;
+Decoration, Vaporous '(ring) tone' 'ring tone'
	soundDesc = "It sounds like most other things you can't hear. "
;
+Decoration '(multiplicative) inverse' 'multiplicative inverse'
	desc() {
		local i, r, txt;

		txt = _outputCapture({: field.desc }).split(nil);
		r = new StringBuffer(txt.length);
		for(i = txt.length; i >= 1; i--)
			r.append(txt[i]);
		"<<r>>\n ";
	}
;
+Decoration '(white) house' 'house'
	"It looks strangely familiar. ";
+Decoration '(twisty) (confusing) forest tree*trees' 'forest'
	"It's a forest of twisty trees, all unimplemented. ";
+Decoration '(boarded) (front) door' 'door'
	"Unimplemented. ";
+Decoration 'board*boards' 'board' "Purely flavor text, stop fiddling with it. "
	dobjFor(Taste) {
		action() { "Not THAT kind of flavor. "; }
	}
;
+me: Person;

houseNorth: OutdoorRoom 'North of House'
	"You are facing the north side of a shamelessly filched white
	house.  There is no door here, and all the windows are Fixtures
	that don't respond to actions. "
	north: FakeConnector { "That part of the forest might show up
		in the DLC. " }
	east = houseEast
	west = houseWest
;
+Decoration '(shamelessly) (filched) (white) house' 'house'
	"It looks strangely familiar. ";
+Decoration 'forest' 'forest'
	"[This forest intentionally left blank]";
+Decoration 'window*windows' 'windows'
	"I just said they don't respond to actions. ";

houseSouth: OutdoorRoom 'South of House'
	"You are facing the south side of a white house.  There are
	no doors, windows, or apologies for the theft of intellectual
	property. "
	east = houseEast
	west = houseWest
;
+Unthing '(intellectual) (property) theft' 'theft'
	'I don\'t know what you\'re talking about. ';
+Unthing '(intellectual) property' 'intellectual property'
	'In this case I\'m use <q>intellectual</q> in the broadest possible
		sense. ';

houseEast: OutdoorRoom 'Behind House'
	"You are behind the white house.  In one corner of the house
	there is a jar which is slightly a window.  Or maybe the other
	way around, this is from memory. "
	north = houseNorth
	south = houseSouth
	west = jarOutside
;
+jarOutside: Door '(slightly) (ajar) jar window' 'jar'
	dobjFor(Open) {
		verify() { nonObvious; }
	}
;

kitchen: Room 'Kitchen'
	"You are in the kitchen of the white house.  The table seems like
	a lot of work to code up so you don't see it.  A passage leads
	to the west, because that's what kitchens have.  Passages.  A
	dark staircase can be seen leading upward, but I don't think it
	can see you.  To the east is a small jar which leads outside. "
	east = jarInside
	west = livingRoom
	up: FakeConnector { "If you try to use the stairs they might see
		you. " }
;
+jarInside: Door '(small) (ajar) jar window' 'jar'
	masterObject = jarOutside;
+Unthing 'table' 'table'
	'Can\'t see anything like that here, nope. ';
+Decoration '(dark) staircase*stairs' 'staircase'
	"Don't make eye contact with the stairs. "
;
+Decoration 'passage*passages' 'passage'
	"This kitchen has an awful lot of passages, for a kitchen.  One.
	One seems like a lot. ";

livingRoom: Room 'Living Room'
	"You are in the living room.  There is a door to the east which
	was a passage when you came in.  In leads to the kitchen.  There's
	also a door to the west that isn't even worth mentioning.  There's
	a trap door leading down which you can see because the rug is at the
	cleaners.  "
	east = kitchen
	west: FakeConnector { "It isn't really isn't even an actual door. " }
	down = trapDoorUp
;
+trapDoorUp: AutoClosingDoor, OneWayRoomConnector '(trap) door' 'trap door'
	dobjFor(Open) { verify() { nonObvious; } };
+Decoration '(west) door' 'door' "Not worth mentioning. ";
+Unthing 'rug' 'rug' 'It really tied the room together. ';


cellar: Room 'Cellar'
	"You are in a dark and damp cellar a crawlway to the south.  To
	the west is a steep metal ramp which doesn't actually exist and
	anyway is unclimbable.  There's a trap door overhead but that's
	no help. "
	west: FakeConnector { "The steep metal ramp doesn't actually
		exist so you can't go up it. " }
	south = westChasm
;
+trapDoorDown: AutoClosingDoor '(trap) door' 'trap door'
	masterObject = trapDoorUp
;
+Decoration '(steep) (metal) ramp' 'ramp'
	"All appearances to the contrary, it doesn't acutally exist. "
;

westChasm: Room 'West of Chasm'
	"You are on the west edge of a chasm which does not in fact have
	an east edge, a topological impossibility that makes the fact that
	you can't see its bottom seem trivial.  A narrow passage goes west,
	but it doesn't lead anywhere relevant to this demo.  The path you're
	on continues north and south. "
	west: FakeConnector { "That's not important.  Pretend it isn't
		even there. " }
	north = cellar
	south = gallery
;
+Decoration '(west) (east) edge chasm bottom' 'chasm'
	"It's best not to even look at the chasm.  Too disturbing. "
;
+Decoration '(narrow) passage' 'passage'
	"I guess it technically isn't a passage if it doesn't lead anywhere. "
;

gallery: Room 'Galleon'
	"This is a gallery, or it least it would be if the author was paying
	more attention.  But they weren't and so this somehow or other is
	a galleon.  It has even fewer paintings than the gallery that
	should be here, so don't bother looking for any.  You can leave
	this madness by going north or south. "
	north = westChasm
	south = studio
;
//+me: Person;
+Decoration 'galleon' 'galleon'
	"Yep, it's a galleon.  For some damn reason. "
;
+Unthing 'gallery' 'gallery'
	'A gallery, all things considered, would make more sense. '
;
+Unthing 'painting*paintings' 'painting'
	'They\'re in some other game. '
;

studio: Room 'Studio'
	"This is what appears to be the orlop of the galleon that really
	shouldn't be north of here but somehow is.  It doesn't, strictly
	speaking, make any sense that the orlop should be south of the
	ship it is ostensibly a part of, but all logic or consistency
	appears to have gone by the board.  Anyway, there's a chimney...an
	orlop chimney apparently, that leads up and an exit to the north. "
	north = gallery
	up = chimneyUp
;
+chimneyUp: Decoration, OneWayRoomConnector 'chimney' 'chimney'
	"\n\tChim-chimney,
	\n\tChim-chimney,
	\n\tChim, chim, cher-bork.
	\n\tThis demo's a silly
	\n\tRipoff of Zork.\n "
	noteTraversal(traveler) {
		"Your trip up the chimney is surprisingly un-noteworthy. ";
	}
	destination = kitchen
;
+Unthing '(artist) studio' 'studio'
	'Apparently it used to be a studio?  Don\'t ask me. '
;
+Decoration 'orlop' 'orlop'
	"It's the lowest deck of the ship.  As if that explains anything. "
;
+Decoration, Distant 'galleon ship' 'galleon'
	"For some reason it has a spanker at mizzen instead of a lateen
	rig, but that's not worth getting into here. "
;
+Decoration, Distant 'spanker sail' 'spanker'
	"It's a kind of fore-and-aft rigged sail. "
;
+Unthing 'lateen rig' 'lateen'
	'It\'s the kind of fore-and-aft sail the ship does not, but should,
	have. ';
+Decoration, Distant 'mizzen mizzenmast mast*masts' 'mizzenmast'
	"It's the aftmost mast on the ship. "
;
+Decoration, Distant 'fore foremast mast*masts' 'foremast'
	"It's the foremost mast on the ship. "
;
+Decoration, Distant 'main mainmast mast*masts' 'mainmast'
	"It's the middle mast on the ship. "
;
