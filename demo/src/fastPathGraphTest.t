#charset "us-ascii"
//
// fastPathGraphTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the fastPath library.
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

#include "fastPath.h"

versionInfo: GameID;
gameMain: GameMainDef
	newGame() {
		local p;

		if((p = graph0.findPath('in', 'out')) == nil) {
			"\nGot nil path\n ";
			return;
		}
		"\nPath:\n ";
		p.forEach(function(o) {
			"\n\t<<toString(o.vertexID)>>\n ";
		});
	}
;

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
