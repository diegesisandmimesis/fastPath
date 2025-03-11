#charset "us-ascii"
//
// fastPathGateway.t
//
//	A "gateway" in our usage is a directed edge connecting one
//	zone to another (call them the "source" and "destination"
//	zones, respective).
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathGateway: FastPathEdge
	// Add a pair of connected rooms that cross the zone boundary
	// represented by the gateway.
	// The first room is in the source zone, the second room is
	// in the destination zone.
	addNextHop(rm0, rm1) {
		if(data == nil)
			data = new Vector();
		data.append(new FastPathNextHopPair(rm0, rm1));
	}

	getNextHop(rm0, rm1) {
		if(data == nil) return(nil);
		return(data.valWhich({ x: x.match(rm0, rm1) }));
	}

	removeNextHop(rm0, rm1) {
		local i;

		if(data == nil) return(nil);
		for(i = 1; i <= data.length; i++) {
			if(data[i].match(rm0, rm1)) {
				data.removeElementAt(i);
				return(true);
			}
		}

		return(nil);
	}

	getNextHops() { return(data ? data : []); }
;

// Data structure holding a pair of vertices that crosses a zone boundary.
class FastPathNextHopPair: object
	src = nil	// the vertex the connection comes from
	dst = nil	// the vertex the connection leads to

	construct(v0?, v1?) {
		src = v0;
		dst = v1;
	}

	// Utility method for comparing next hop pairs.
	match(v0, v1) { return((src == v0) && (dst == v1)); }
;

// Data structure for holding data about a next hop path.
// This is used when a two zones are connected at more than one point
// and we have to decide which path is shorter.
class FastPathNextHopPick: object
	nextHop = nil		// the "destination" vertex being considered
	pathThroughZone = nil	// the computed path through the destination
				// 	zone when pathed throught this vertex

	construct(v0?, v1?) {
		nextHop = v0;
		pathThroughZone = v1;
	}
;
