#charset "us-ascii"
//
// fastPathPreinit.t
//
//	Here we handle the logic for treating other object classes--like
//	rooms--as vertices in a graph.
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

// Singleton that handles pre-init for FastPathPreinit instances.
// We don't just add PreinitObject to FastPathPreinit itself because
// to avoid collisions with other stuff already using execute().  Basically
// the whole point of FastPathPreinit is to act as a graph layer on top
// of existing kinds of objects, and they might already have their
// own execute() methods.
fastPathInit: PreinitObject
	execute() {
		forEachInstance(FastPathPreinit, { x: x.initializeFastPath() });
	}
;

// Data structure consisting of a zoneID and a vertexID.  This is used
// by fastPathGroup(), which takes object instances (for example rooms)
// and figures out what zone they belong in and what vertex ID to use
// for them.
// A zone in this usage is just a subgraph that gets its own lookup table
// for path finding.
class FastPathGroup: object
	zoneID = nil
	vertexID = nil
	construct(v0?, v1?) {
		zoneID = v0;
		vertexID = v1;
	}
;

class FastPathPreinit: FastPathMap
	// Object class we're using as vertices.
	fastPathObjectClass = nil

	initializeFastPath() {
		local v, z;

		// If there's no definied object class for us, we have nothing
		// to do.
		if(fastPathObjectClass == nil)
			return;

		// Iterate over all the instances of the object type we care
		// about and add them as vertices.
		forEachInstance(fastPathObjectClass, function(o) {
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

			o.fastPathZone = z.zoneID;
			o.fastPathVertex = v;

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
