#charset "us-ascii"
//
// fastPathGraph.t
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathGraph: Graph
	vertexClass = FastPathVertex

	generateNextHopCache() {
		local l, p;

		l = getVertices();
		l.forEach(function(v0) {
			l.forEach(function(v1) {
				if(v0 == v1) return;
				if((p = getDijkstraPath(v0, v1)) == nil) return;
				if(p.length < 2) return;
				v0.setNextHop(v1.vertexID, getVertex(p[2]));
			});
		});
	}
	clearNextHopCache() {
		getVertices().forEach({ x: x.clearNextHopCache() });
	}
	getNextHop(v0, v1) {
		if((v0 = canonicalizeVertex(v0)) == nil) return(nil);
		if((v1 = canonicalizeVertex(v1)) == nil) return(nil);
		return(v0.getNextHop(v1.vertexID));
	}

	findFastPath(v0, v1) {
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
