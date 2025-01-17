#charset "us-ascii"
//
// fastPathZone.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

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

// A gateway is a point of contact between two zones.  In our usage gateways
// always have an implied orientation--a gateway is from one zone to another
// zone, not to AND from (because pathing may not be symmetric).
class FastPathGateway: object
	src = nil		// vertex in one zone that leads to the other
	dst = nil		// vertex in the other zone src leads to
	construct(v0?, v1?) {
		src = v0;
		dst = v1;
	}
;

class FastPathMap: FastPathGraph
	// To hold graph of the zones.
	gateways = nil

	// Object class we're mapping.
	fastPathObjectClass = nil

	// If a vertex ID isn't provided by the object, it'll be
	// assigned on using this plus the vertex number.
	fastPathIDBase = 'fastPathNode'

	// Called at preinit.
	// Here's where we iterate over all of our objects and try to build
	// a graph corresponding to how they're connected.
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

			// Add the zone ID to this instance.
			o.fastPathZone = z.zoneID;

			// Have it remember its vertex.
			o.fastPathVertex = v;

			// Make the data property on the vertex a pointer
			// to the instance.
			v.data = o;
		});

		// Now go back through the vertices we just added and
		// call our method to add their edges.
		getVertices().forEach({ x: fastPathAddEdges(x) });

	}

	// Method that associates an object with a zone ID and a
	// vertex ID.  Intended to be overwritten by subclasses.
	// See RoomPathfinder for an example.
	fastPathGrouper(obj) {
		if(obj == nil) return(nil);
		return(new FastPathGroup(getFastPathZone(obj),
			getFastPathID(obj)));
	}

	// Add all the edges associated with this object.  Intended to
	// be overwitten by subclasses.  See RoomPathfinder for an example.
	// Here we just test that the object is a vertex and return a
	// boolean indicating the result.  This is so subclasses can
	// do a "if(!inherited(obj)) return(nil);" or the like at the top.
	fastPathAddEdges(obj) {
		if(!isVertex(obj)) return(nil);
		return(true);
	}

	// Returns the zone ID associated with the object.
	getFastPathZone(obj) {
		if(obj == nil) return(nil);
		return(obj.fastPathZone ? obj.fastPathZone : 'default');
	}

	// Returns the vertex ID (in the pathfinding graph) for the object.
	// Most of the logic is to provide a unique-ish default if a value
	// isn't provided.
	getFastPathID(obj) {
		local id, n;

		// Object can't be nil
		if(obj == nil)
			return(nil);

		// If the object has a declared fastPathID, use it, done.
		if(obj.fastPathID != nil)
			return(obj.fastPathID);

		// Loop to assign a generic "obj#123"-style unique-ish
		// vertex ID.
		n = getVertices().length();
		id = fastPathIDBase + '#' + toString(n);
		while(getVertex(id) != nil) {
			n += 1;
			id = fastPathIDBase + '#' + toString(n);
		}

		// Add it to the object.
		obj.fastPathID = id;

		return(obj.fastPathID);
	}

	createNextHopCache() {
		local id, t;

		// Temporary lookup table.  We use this to build a table
		// of vectors keyed by zone ID where each vector contains
		// all the vertices in that zone.
		t = new LookupTable();

		// The gateway map is a graph.
		gateways = new FastPathGraph();

		getVertices().forEach(function(o) {
			// If there's a fastPathZone property on the data
			// in the vertex, use it.  Otherwise the zone
			// is "default".
			id = ((o.data && o.data.fastPathZone)
				? o.data.fastPathZone
				: 'default');

			// If we don't already have a table entry for
			// the zone ID, create it.
			if(t[id] == nil)
				t[id] = new Vector();

			// Add the vertex to the vector.
			t[id].append(o);

			// We separately add the zone ID to the gateway
			// graph if it isn't already there.  We don't JUST
			// use the gateway graph (instead of a temp table)
			// because the gateway graph doesn't keep track of
			// all the vertices in the "main" graph, just the
			// zones.
			if(gateways.getVertex(id) == nil) {
				gateways.addVertex(id);
			}
		});

		// Now go through our table and create next hop caches
		// using our zone vectors.  This means that each vertex
		// will get a next hop cache containing ONLY the other
		// vertices in the same zone.
		t.valsToList().forEach(function(l) {
			l.forEach({ x: _createNextHopCacheForVertex(x, l) });
		});

		// Now figure out how the zones are connected to each other.
		addFastPathGateways();
	}

	// Build the connections in the gateway graph.  The vertices are
	// added in createNextHopCache() above.
	addFastPathGateways() {
		local v1;

		// Iterate through each vertex in the "main" graph.
		getVertices().forEach(function(v0) {
			// Now iterate through each edge on each vertex.
			v0.getEdgeIDs().forEach(function(e) {
				// If the other side of the edge isn't
				// a valid vertex, fail.  Should never happen.
				if((v1 = getVertex(e)) == nil) return;

				// Add a gateway corresponding to the
				// two vertices, if necessary.
				_addFastPathGateway(v0, v1);
			});
		});

		gateways.createNextHopCache();
	}

	// Add a gateway between two vertices, if necessary.
	// A gateway is a connection between two zones.
	_addFastPathGateway(v0, v1) {
		local e, id0, id1;

		// Make sure both arguments are vertices.
		if(!isVertex(v0) || !isVertex(v1)) return(nil);

		// Make sure both vertices have data.
		if((v0.data == nil) || (v1.data == nil)) return(nil);

		// If both vertices are in the same zone we have nothing
		// to do.
		if(v0.data.fastPathZone == v1.data.fastPathZone) return(nil);

		id0 = v0.data.fastPathZone;
		id1 = v1.data.fastPathZone;

		// If we don't already have a gateway between the two
		// zones, create it.  NOTE:  an edge from zone 1 to zone 2
		// does not imply an edge from zone 2 to zone 1.
		if((e = gateways.getEdge(id0, id1)) == nil)
			e = gateways.addEdge(id0, id1);

		// We use the edge's data property to keep track of what
		// vertices are on either side.  In the "normal" graph
		// that's the edge itself, but here the vertices are zones,
		// and each zone can theoretically bet connected to each
		// other zone via multiple edges.
		if(e.data == nil)
			e.data = new Vector();

		// Add a new gateway instance to the edge data.
		e.data.append(new FastPathGateway(v0, v1));

		return(true);
	}

	findPath(v0, v1) { return(findPathWithZones(v0, v1)); }

	// Zone-aware pathfinding routine.
	findPathWithZones(v0, v1) {
		local e, i, r, v, z0, z1, zp;

		// Make sure the inputs are valid.
		if((v0 = canonicalizeVertex(v0)) == nil) return([]);
		if((v1 = canonicalizeVertex(v1)) == nil) return([]);

		// If both endpoints are in the same zone, use the
		// default (non-zone-aware) method.
		if(v0.data && v1.data
			&& (v0.data.fastPathZone == v1.data.fastPathZone))
			return(findPathInSingleZone(v0, v1));

		// Make sure both zones exists.
		if((z0 = gateways.getVertex(v0.data.fastPathZone)) == nil)
			return([]);
		if((z1 = gateways.getVertex(v1.data.fastPathZone)) == nil)
			return([]);

		// Get a path through the zones.
		if((zp = gateways.findPath(z0, z1)) == nil) return([]);

		// To hold the path.
		r = new Vector();

		// Make the start vertex the current vertex.
		v = v0;

		// Evaluate all the pairs of zones:  1st and 2nd, 2nd
		// and 3rd, and so on.
		for(i = 2; i <= zp.length; i++) {
			// Get the edge between the previous zone and the
			// current one.
			e = gateways.getEdge(zp[i - 1], zp[i]);

			// The edge data will be a list of gateways;  pick
			// one.
			e = e.data[1];

			// Add the path between the current vertex and
			// the near-side gateway.  That's all the vertices
			// in the path in the previous zone.
			r.appendAll(findPathInSingleZone(v, e.src));
			
			// Make the far side gateway the current vertex.
			v = e.dst;
		}

		// The loop above handles everything except the last
		// zone.
		if(v != v1) {
			// If the current vertex--which will be the far side
			// gateway from the perspective of the last-but-one
			// zone--is NOT the destination vertex, add the path
			// from it to the destination vertex.  This will be
			// the path through the last zone.
			r.appendAll(findPathInSingleZone(v, v1));
		} else {
			// If the current vertex IS the destination vertex,
			// we just have to add it.
			r.append(v);
		}

		return(r);
	}
;
