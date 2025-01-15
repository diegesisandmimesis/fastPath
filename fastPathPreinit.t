#charset "us-ascii"
//
// fastPathPreinit.t
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

fastPathInit: PreinitObject
	execute() {
		forEachInstance(FastPathPreinit, { x: x.initializeFastPath() });
	}
;

class FastPathZone: object
	zoneID = nil
	vertexID = nil
	construct(v0?, v1?) {
		zoneID = v0;
		vertexID = v1;
	}
;

class FastPathPreinit: FastPathGraph
	fastPathType = nil
	initializeFastPath() {
		local v, z;

		// If there's no definied object class for us, we have nothing
		// to do.
		if(fastPathType == nil)
			return;

		// Iterate over all the instances of the object type we care
		// about and add them as vertices.
		forEachInstance(fastPathType, function(o) {
			// Pass this instance to our grouper.  If it doesn't
			// provide us with a zone and vertex ID, bail.
			if((z = fastPathGrouper(o)) == nil)
				return;

			// If the requested vertex ID is already in our
			// graph, we're done.
			if((v = getVertex(z.vertexID)) != nil)
				return;

			// Add the vertex.
			v = addVertex(z.vertexID);

			// Make the data property on the vertex a pointer
			// to the instance.
			v.data = o;
		});

		// Now go back through the vertices we just added and
		// call our method to add their edges.
		getVertices().forEach({ x: fastPathAddEdges(x) });
	}

	fastPathGrouper(obj) { return(nil); }
	fastPathAddEdges(obj) {
		if(!isVertex(obj)) return(nil);
		return(true);
	}

;
