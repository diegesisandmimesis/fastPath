#charset "us-ascii"
//
// fastPathVertex.t
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathVertex: Vertex
	// Per-vertex user data.  If the graph is used for room
	// traversal, for example, this will be a pointer to a
	// room instance.
	data = nil

	// Lookup table to hold next hope info for this vertex.
	nextHopCache = perInstance(new LookupTable())

	nextHopCacheSpecial = nil

	// Flag indicating that the next hop cache needs to be re-computed.
	nextHopCacheDirty = true

	// Returns the cache entry for the given vertex.  Does not create
	// the cache data if it doesn't already exist.
	getNextHop(id, z?) {
		local t;

		if(isVertex(id)) id = id.vertexID;
		if(z == nil)
			return(nextHopCache[id]);
		if((t = nextHopCacheSpecial[z]) == nil)
			return(nil);
		return(t[id]);
	}

	// Adds an entry to the cache.  First arg is the destination
	// vertex, second is the adjacent vertex that leads to it.
	setNextHop(id, v, z?) {
		local t;

		if(isVertex(id)) id = id.vertexID;
		if(z == nil) {
			nextHopCache[id] = v;
			return(true);
		}
		if((t = nextHopCacheSpecial[z]) == nil) {
			t = new LookupTable();
			nextHopCacheSpecial[z] = t;
		}
		t[id] = v;
		return(true);
	}

	// Clear the cache.
	clearNextHopCache(z?) {
		if(z == nil) {
			nextHopCache = new LookupTable();
			nextHopCacheDirty = true;
		} else {
			if(nextHopCacheSpecial[z] != nil)
				nextHopCacheSpecial[z] = new LookupTable();
		}
	}
;
