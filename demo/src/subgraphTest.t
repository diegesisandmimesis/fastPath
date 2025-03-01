#charset "us-ascii"
//
// subgraphTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a copy of demo/src/zoneTest.t with an initial configuration
// that includes non-contiguous zones.  This is intended to test
// the automatic subgraph detection/fixing code.
//
// It can be compiled via the included makefile with
//
//	# t3make -f subgraphTest.t3m
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

	newGame() {
		local l;

		pathfinder.initializeFastPathMap();
		pathfinder.createFastPathCache();

		// First we see if there's a path.  This should fail
		// because "foo" consists of two disjoin subgraphs.
		l = pathfinder.findPath('foo1', 'bar3');
		if(pathfinder.testPath('foo1', 'bar3', l)) {
			"\nFAILED:  found impossible path.\n ";
			return;
		}

		pathfinder.verifyFastPathZone('zoneX');

		l = pathfinder.findPath('foo1', 'bar3');
		if(pathfinder.testPath('foo1', 'bar3', l)) {
			"\npassed all tests\n ";
		} else {
			"\npathfinding FAILED\n ";
		}
	}
;

me: Person;

pathfinder: FastPathMap
	fastPathObjectClass = DemoObject
	fastPathZoneClass = DemoZone

	findPath(v0, v1) {
		local l, r;

		l = inherited(v0, v1);
		r = new Vector(l.length);
		l.forEach({ x: r.append(x.vertexID) });

		return(r.toList());
	}
;

class DemoZone: FastPathZone
	addFastPathGateways(v) {
		if(!isVertex(v) || !v.data || !v.data.ofKind(DemoObject))
			return(nil);

		v.data.getEdges().forEach(function(o) {
			if(getVertex(o) == nil) {
				queueFastPathGateway([ v, o ]);
				return;
			}

			addEdge(v, o);
		});

		return(true);
	}
;

class DemoObject: object
	edges = nil
	getEdges() { return(edges ? edges : []); }
;

// IMPORTANT:  Our only meaningful change to demo/src/zoneTest.t is
// to declare the same zone ID for both Foo and Bar.  This is creates
// two blobs of objects with the same ID separated by a blob of objects
// with a different ID.  This is not allowed by the fastPath pathfinding
// logic, so it should be fixed by verifyFastPathZone().
class Foo: DemoObject fastPathZone = 'zoneX';
class Bar: DemoObject fastPathZone = 'zoneX';
class Baz: DemoObject fastPathZone = 'zoneY';

foo1: Foo fastPathID = 'foo1' edges = static [ 'foo2', 'foo3' ];
foo2: Foo fastPathID = 'foo2' edges = static [ 'foo1', 'foo3' ];
foo3: Foo fastPathID = 'foo3' edges = static [ 'foo1', 'foo2', 'baz1' ];
bar1: Bar fastPathID = 'bar1' edges = static [ 'bar2', 'bar3', 'baz1' ];
bar2: Bar fastPathID = 'bar2' edges = static [ 'bar1', 'bar3' ];
bar3: Bar fastPathID = 'bar3' edges = static [ 'bar2', 'bar1' ];
baz1: Baz fastPathID = 'baz1' edges = static [ 'foo3', 'bar1' ];
