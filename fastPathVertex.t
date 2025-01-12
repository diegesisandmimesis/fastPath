#charset "us-ascii"
//
// fastPathVertex.t
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathVertex: Vertex
	nextHopCache = perInstance(new LookupTable())

	getNextHop(id) { return(nextHopCache[id]); }
	setNextHop(id, v) {
		nextHopCache[id] = v;
	}

	clearNextHopCache() { nextHopCache = new LookupTable(); }
;
