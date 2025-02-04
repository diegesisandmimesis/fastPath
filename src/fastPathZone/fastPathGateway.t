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

	getNextHops() { return(data); }
;

class FastPathNextHopPair: object
	src = nil
	dst = nil
	construct(v0?, v1?) {
		src = v0;
		dst = v1;
	}
	match(v0, v1) { return((src == v0) && (dst == v1)); }
;

class FastPathNextHopPick: object
	nextHop = nil
	pathThroughZone = nil
	construct(v0?, v1?) {
		nextHop = v0;
		pathThroughZone = v1;
	}
;
