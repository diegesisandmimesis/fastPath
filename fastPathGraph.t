#charset "us-ascii"
//
// fastPathGraph.t
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathGraph: DirectedGraph
	vertexClass = FastPathVertex
	edgeClass = FastPathEdge

	// If true, cache will be created if it doesn't already exist
	autoCreateFastPathCache = true

	// In the base class all we have to do is create the next hop
	// caches for each vertex.
	createNextHopCache() {
		getVertices().forEach({ x : _createNextHopCacheForVertex(x) });
	}

	// Create a next-hop cache for the given vertex.
	// Second arg is the list of all destinations to create next-hop
	// data for.
	_createNextHopCacheForVertex(v0, lst?) {
		local p; 

		// If we don't have an explicit list, it's all the vertices
		// in the graph.
		if(lst == nil)
			lst = getVertices();

		// Go through each vertex in the list and compute the (full)
		// path from the start vertex to it.  Then we remember
		// just the first step (the next hop from v0).
		lst.forEach(function(v1) {
			if(v0 == v1) return;
			if((p = getDijkstraPath(v0, v1)) == nil) return;
			if(p.length < 2) return;
			v0.setNextHop(v1, getVertex(p[2]));
		});

		// Mark the cache as clean.
		v0.nextHopCacheDirty = nil;
	}

	clearNextHopCache() {
		getVertices().forEach({ x: x.clearNextHopCache() });
	}

	getNextHop(v0, v1) {
		if((v0 = canonicalizeVertex(v0)) == nil) return(nil);
		if((v1 = canonicalizeVertex(v1)) == nil) return(nil);
		if(v0.nextHopCacheDirty && autoCreateFastPathCache)
			_createNextHopCacheForVertex(v0);
		return(v0.getNextHop(v1.vertexID));
	}

	findPathInSingleZone(v0, v1) {
		local r, v;

		if((v0 = canonicalizeVertex(v0)) == nil) return([]);
		if((v1 = canonicalizeVertex(v1)) == nil) return([]);

		r = new Vector();
		v = v0;

		while(v != nil) {
			r.append(v);

			if(v == v1) return(r);

			v = getNextHop(v, v1);
		}

		return(r);
	}

	findPath(v0, v1) { return(findPathInSingleZone(v0, v1)); }

	testPath(v0, v1, lst) {
		if(!lst || !lst.length) return(nil);
		return(canonicalizeVertex(v1)
			== canonicalizeVertex(lst[lst.length]));
	}
;
