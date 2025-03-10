#charset "us-ascii"
//
// fastPathGraphTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a minimal test of the base fastPathGraph pathfinder.
//
// It can be compiled via the included makefile with
//
//	# t3make -f fastPathGraphTest.t3m
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
	// All we do is call the graph's verifyPath() method.  It attempts
	// to compute the path between the vertices given as the first
	// two args.  It then compares the computed path to the third
	// arg, returning boolean true if they match, nil otherwise.
	newGame() {
		"\n ";
		if(graph0.verifyPath('in', 'out',
			[ 'in', 'foo', 'baz', 'out' ])) {
			"passed all tests";
		} else {
			"ERROR:  pathfinding produced invalid path";
		}
		"\n ";
	}
;

// Five node graph.  The "in" node is connected only to "foo";
// "out" is connected to "baz", and "foo", "bar", and "baz" are all
// connected to each other.
graph0: FastPathGraph
	[	'in',	'foo',	'bar',	'baz',	'out'	]
	[
		0,	1,	0,	0,	0,
		1,	0,	1,	1,	0,
		0,	1,	0,	1,	0,
		0,	1,	1,	0,	1,
		0,	0,	0,	0,	1
	]
;
