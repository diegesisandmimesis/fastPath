#charset "us-ascii"
//
// zoneTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is indended as a minimialistic test of zone-aware pathfinding.
// In particular we define our own object class, instead of using Room,
// to exercise the non-room-based zone pathfinding code.
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

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me

	newGame() {
		local l;

		pathfinder.initializeFastPathMap();
		pathfinder.createFastPathCache();
		l = pathfinder.findPath('start', 'exit');
		if(!pathfinder.testPath('start', 'exit', l))
			"\npathfinding FAILED\n ";
		else
			"\npassed all tests\n ";
	}
;

me: Person;

// Pathfinder.
pathfinder: FastPathMap
	// Our subclasses
	fastPathObjectClass = DemoObject
	fastPathZoneClass = DemoZone

	// Tweak the pathfinder to return a list of IDs instead of a
	// list of vertices.
	findPath(v0, v1) {
		local l, r;

		l = inherited(v0, v1);
		r = new Vector(l.length);
		l.forEach({ x: r.append(x.vertexID) });

		return(r.toList());
	}
;

// Our bespoke zone class.
// In a zone-aware pathfinder the subclass of FastPathZone has to
// supply the logic for figuring out how to translate a object into
// a vertex and how to figure out which vertices are connected.
// By default FastPathVertex just stuffs the object into a vertex's
// .data property.
// There is no default edge-finding algorithm.  Here we provide one,
// which just consists of declaring an .edges property on each object
// and using it to get the IDs of objects this object is connected to.
// The corresponding logic in the room pathfinder figures out which
// rooms are connected to a given room, for example.
class DemoZone: FastPathZone
	addFastPathGateways(v) {
		// We need the arg to be a vertex and it has to have
		// a DemoObject as its data.
		if(!isVertex(v) || !v.data || !v.data.ofKind(DemoObject))
			return(nil);

		// Call DemoObject.getEdges() to enumerate the
		// edges.  Each element is a object ID this object is
		// connected to.
		v.data.getEdges().forEach(function(o) {
			// If the object ID doesn't correspond to a vertex
			// in this zone, that means the edge crosses a zone
			// boundary.  When that happens we queue it up as
			// a gateway instead of adding it as an edge.
			if(getVertex(o) == nil) {
				queueFastPathGateway([ v, o ]);
				return;
			}

			// We DID know about the other vertex, which means
			// it's a vertex in this zone.  That means we can
			// create a "normal" edge.
			addEdge(v, o);
		});

		return(true);
	}
;

// Silly object class.
// The only reason we're doing this is to make sure we don't accidentally
// bake room-specific dependencies into the zone pathfinding logic.
// Our object class is just a bare object with an .edges property and
// a method to return it.
class DemoObject: object
	edges = nil
	getEdges() { return(edges ? edges : []); }
;

// We create subclasses so we only have to declare the zone ID once each.
class Start: DemoObject fastPathZone = 'start';
class Foo: DemoObject fastPathZone = 'foo';
class Bar: DemoObject fastPathZone = 'bar';
class Exit: DemoObject fastPathZone = 'exit';

// Individual object instance declarations.  They're just an ID and a
// list of edges.
// This is an inefficient way to do this, but we're only doing this to
// exercise the object-agnostic zone code.
startRoom: Start fastPathID = 'start' edges = static [ 'foo1' ];
foo1: Foo fastPathID = 'foo1' edges = static [ 'start', 'foo2' ];
foo2: Foo fastPathID = 'foo2' edges = static [ 'foo1', 'foo3' ];
foo3: Foo fastPathID = 'foo3' edges = static [ 'foo2', 'bar1' ];
bar1: Bar fastPathID = 'bar1' edges = static [ 'foo3', 'bar2' ];
bar2: Bar fastPathID = 'bar2' edges = static [ 'bar1', 'bar3' ];
bar3: Bar fastPathID = 'bar3' edges = static [ 'bar2', 'exit' ];
exitRoom: Exit fastPathID = 'exit' edges = static [ 'bar3' ];
