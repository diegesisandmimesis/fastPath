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

#include "fastPath.h"

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		local l;

		// We have to manually initialize the cache because we're
		// using wacky bespoke non-room objects so we're ONLY
		// relying on the base pathfinder code (and not the
		// room-specific extensions).
		pathfinder.initializeFastPathMap();
		pathfinder.createFastPathCache();

		// First we see if there's a path.  This should fail
		// because "foo" consists of two disjoint subgraphs.
		l = pathfinder.findPath('foo1', 'bar3');
		if(pathfinder.testPath('foo1', 'bar3', l)) {
			"\nFAILED:  found impossible path.\n ";
			return;
		}

		// Ask the pathfinder to check the given zone for
		// subgraphs.
		// We have to do this manually because we're using weird
		// bespoke objects for this demo; with the room pathfinder
		// this happens automagically during preinit.
		pathfinder.verifyFastPathZone('zoneX');

		// Now pathfinding should work.  We use the verifyPath()
		// method to see if the pathfinder is producing the
		// result we want.
		if(pathfinder.verifyPath('foo1', 'bar3', [
				'foo1', 'foo3', 'baz1', 'bar1', 'bar3'
			])) {
			"\npassed all tests\n ";
		} else {
			"\npathfinding FAILED\n ";
		}
	}
;

me: Person;

// We create a one-off FastPathMap subclass to handle our DemoObject
// instances.
pathfinder: FastPathMap
	fastPathObjectClass = DemoObject
	fastPathZoneClass = DemoZone

	// We update the findPath() method to return a list of vertex
	// IDs instead of Vertex instances.
	// This is just to make testing easier.
	findPath(v0, v1) {
		local l, r;

		l = inherited(v0, v1);
		r = new Vector(l.length);
		l.forEach({ x: r.append(x.vertexID) });

		return(r.toList());
	}

	// Update FastPathMap.resolveVertex() to work with our
	// DemoObject class.  This is basically the same thing
	// the room pathfinder does, but we're not using Room instances
	// so we have to re-implement things ourselves.
	resolveVertex(v) {
		local z;

		if((v != nil) && (v.ofKind(DemoObject))) {
			if((z = getZone(v.fastPathZone)) == nil)
				return(nil);
			return(z.canonicalizeVertex(v));
		}
		return(inherited(v));
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

	// Tweak to FastPathZone.resolveVertex() to work with our
	// DemoObject class.
	resolveVertex(v) {
		if((v != nil) && (v.ofKind(DemoObject)))
			return(inherited(v.fastPathID));
		return(inherited(v));
	}
;

class DemoObject: object
	edges = nil
	getEdges() { return(edges ? edges : []); }
;

// We (stupidly) put the same zone ID on the "Foo" and "Bar" rooms.
// This creates a zone in two discontinuous blobs, which will case
// the pathfinder to fail.
class Foo: DemoObject fastPathZone = 'zoneX';
class Bar: DemoObject fastPathZone = 'zoneX';
class Baz: DemoObject fastPathZone = 'zoneY';

// foo1, foo2, and foo3 are all connected to each other;  only foo3
// is connected to baz1.
foo1: Foo fastPathID = 'foo1' edges = static [ 'foo2', 'foo3' ];
foo2: Foo fastPathID = 'foo2' edges = static [ 'foo1', 'foo3' ];
foo3: Foo fastPathID = 'foo3' edges = static [ 'foo1', 'foo2', 'baz1' ];

// bar1, bar2, and bar3 are all connected to each other;  only bar1
// is connected to baz1.
bar1: Bar fastPathID = 'bar1' edges = static [ 'bar2', 'bar3', 'baz1' ];
bar2: Bar fastPathID = 'bar2' edges = static [ 'bar1', 'bar3' ];
bar3: Bar fastPathID = 'bar3' edges = static [ 'bar2', 'bar1' ];

// baz1 is connected to foo3 and bar1.
baz1: Baz fastPathID = 'baz1' edges = static [ 'foo3', 'bar1' ];
