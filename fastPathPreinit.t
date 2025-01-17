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

/*
class FastPathPreinit: FastPathMap
	// Object class we're using as vertices.
	fastPathObjectClass = nil

	fastPathIDBase = 'fastPathNode'

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

	fastPathGrouper(obj) {
		if(obj == nil) return(nil);
		return(new FastPathGroup(getFastPathZone(obj),
			getFastPathID(obj)));
	}

	fastPathAddEdges(obj) {
		if(!isVertex(obj)) return(nil);
		return(true);
	}

	getFastPathZone(obj) {
		if(obj == nil) return(nil);
		return(obj.fastPathZone ? obj.fastPathZone : 'default');
	}

	getFastPathID(obj) {
		local id, n;

		if(obj == nil) return(nil);
		if(obj.fastPathID != nil) return(obj.fastPathID);
		n = getVertices().length();
		id = fastPathIDBase + '#' + toString(n);
		while(getVertex(id) != nil) {
			n += 1;
			id = fastPathIDBase + '#' + toString(n);
		}

		obj.fastPathID = id;

		return(obj.fastPathID);
	}
;
*/
class FastPathPreinit: object;
