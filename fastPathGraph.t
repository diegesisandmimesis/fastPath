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

	createNextHopCache() {
		local l;

		l = getVertices();
		l.forEach({ x : _createNextHopCacheForVertex(x, l) });
	}

	_createNextHopCacheForVertex(v0, lst?) {
		local p; 

		if(lst == nil) lst = getVertices();
		lst.forEach(function(v1) {
			if(v0 == v1) return;
			if((p = getDijkstraPath(v0, v1)) == nil) return;
			if(p.length < 2) return;
			v0.setNextHop(v1, getVertex(p[2]));
		});
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

	findPath(v0, v1) {
		local r, v;

		if((v0 = canonicalizeVertex(v0)) == nil) return(nil);
		if((v1 = canonicalizeVertex(v1)) == nil) return(nil);

		r = new Vector();
		v = v0;

		while(v != nil) {
			r.append(v);

			if(v == v1) return(r);

			v = getNextHop(v, v1);
		}

		return(r);
	}
;
