#charset "us-ascii"
//
// fastPathGraph.t
//
//	Extensions to the Graph class for pathfinding.
//
//	We always use directed graphs because paths may be asymmetrical.
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathGraph: DirectedGraph
	// If true, cache will be created if it doesn't already exist
	autoCreateFastPathCache = true

	// Classes to use for vertices and edges.
	vertexClass = FastPathVertex
	edgeClass = FastPathEdge

	graphUpdated() {
		inherited();
		clearFastPathCache();
	}

	// In the base class all we have to do is create the next hop
	// caches for each vertex.
	createFastPathCache() {
		getVertices().forEach({ x : _createFastPathCacheForVertex(x) });
	}

	// Create a next-hop cache for the given vertex.
	// Second arg is the list of all destinations to create next-hop
	// data for.
	_createFastPathCacheForVertex(v0, lst?) {
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
			v0.setFastPath(v1, getVertex(p[2]));
		});

		// Mark the cache as clean.
		v0.fastPathCacheDirty = nil;
	}

	clearFastPathCache() {
		getVertices().forEach({ x: x.clearFastPathCache() });
	}

	resetFastPathCache() {
		clearFastPathCache();
		createFastPathCache();
	}

	// Returns the next step in the path from vertex v0 to vertex v1.
	getFastPath(v0, v1) {
		// Make sure the args are valid.
		if((v0 = canonicalizeVertex(v0)) == nil) return(nil);
		if((v1 = canonicalizeVertex(v1)) == nil) return(nil);

		// If the cache is marked as dirty and we're configured
		// to create the cache automatically, do so now.
		if(v0.fastPathCacheDirty && autoCreateFastPathCache)
			_createFastPathCacheForVertex(v0);

		// Ask the vertex what the next hop is.
		return(v0.getFastPath(v1.vertexID));
	}

	// Pathfinding method that assumes that both vertices are part
	// of a single zone.
	findSingleZonePath(v0, v1, n?) {
		local r, v;

		// Make sure the args are valid.
		if((v0 = canonicalizeVertex(v0)) == nil) return([]);
		if((v1 = canonicalizeVertex(v1)) == nil) return([]);

		// Vector for return value.
		r = new Vector();

		// Start out at the first vertex.
		v = v0;

		// Keep going until we get an error.
		while(v != nil) {
			// Add the current vertex to the path.
			r.append(v);

			// If the current vertex is the desination vertex, we're
			// done.
			if(v == v1) return(r);

			// Get the next hop between the current vertex and
			// the desination vertex.
			v = getFastPath(v, v1);
		}

		// Return the path.
		return(r);
	}

	// By default we're NOT zone-aware, so pathfinding defaults to
	// the single zone method.
	findPath(v0, v1, n?) { return(findSingleZonePath(v0, v1, n)); }

	// Simple test mechanism.  Given two vertices and a path list,
	// verify that the last item in the list is the destination vertex.
	testPath(v0, v1, lst) {
		if(!lst || !lst.length) return(nil);
		return(canonicalizeVertex(v1)
			== canonicalizeVertex(lst[lst.length]));
	}
;
