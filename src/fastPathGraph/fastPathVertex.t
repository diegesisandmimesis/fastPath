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

	// Lookup table to hold next hop info for this vertex.
	fastPathCache = perInstance(new LookupTable())

	// Flag indicating that the next hop cache needs to be re-computed.
	fastPathCacheDirty = true

	// Returns the cache entry for the given vertex.  Does not create
	// the cache data if it doesn't already exist.
	getFastPath(id) {
		if(isVertex(id)) id = id.vertexID;
		return(fastPathCache[id]);
	}

	// Adds an entry to the cache.  First arg is the destination
	// vertex, second is the adjacent vertex that leads to it.
	setFastPath(id, v) {
		if(isVertex(id)) id = id.vertexID;
		fastPathCache[id] = v;
		return(true);
	}

	// Clear the cache.
	clearFastPathCache() {
		fastPathCache = new LookupTable();
		fastPathCacheDirty = true;
	}
;
