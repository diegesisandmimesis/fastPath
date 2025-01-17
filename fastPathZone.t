#charset "us-ascii"
//
// fastPathZone.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

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
	gateways = nil

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

/*
	getNextHop(v0, v1) {
		local z0, z1;

		// Make sure we have valid vertices.
		if((v0 = canonicalizeVertex(v0)) == nil) return(nil);
		if((v1 = canonicalizeVertex(v1)) == nil) return(nil);

		// Make sure the vertices have data.
		if((v0.data == nil) || (v1.data == nil)) return(nil);

		// Make sure the vertex data includes zone IDs.
		if((z0 = v0.data.fastPathZone) == nil) return(nil);
		if((z1 = v1.data.fastPathZone) == nil) return(nil);

		// If vertices are in difference zones...
		if(z0 != z1)
			return(getNextHopViaGateway(v0, v1, z0, z1));

		if(v0.nextHopCacheDirty && autoCreateFastPathCache)
			_createNextHopCacheForVertex(v0);

		return(v0.getNextHop(v1.vertexID));
	}

	getNextHopViaGateway(v0, v1, z0, z1) {
		local gw, e, n, z;

		// Get the gateway vertex for the first zone...
		if((z = gateways.getVertex(z0)) == nil) return(nil);

		// Get the next vertex in the zone path...
		if((n = z.getNextHop(z1)) == nil) return(nil);

		// Get the edge between the first zone and the next...
		if((e = gateways.getEdge(z0, n)) == nil) return(nil);

		// Make sure the edge has gateway data.
		if(e.data == nil) return(nil);

		gw = e.data[1];

		// If the first vertex is the source end of the gateway,
		// then the next hop is the destination end of the gateway.
		if(gw.src == v0)
			return(gw.dst);

		// We're not at the gateway, so our next hop is the next
		// step we need to take toward the source end of the gateway.
		return(v0.getNextHop(gw.src));
	}
*/

	findPath(v0, v1) {
		local e, i, r, v, z0, z1, zp;

		if((v0 = canonicalizeVertex(v0)) == nil) return(nil);
		if((v1 = canonicalizeVertex(v1)) == nil) return(nil);
		if(v0.data && v1.data
			&& (v0.data.fastPathZone == v1.data.fastPathZone))
			return(inherited(v0, v1));

		if((z0 = gateways.getVertex(v0.data.fastPathZone)) == nil)
			return(nil);
		if((z1 = gateways.getVertex(v1.data.fastPathZone)) == nil)
			return(nil);

		if((zp = gateways.findPath(z0, z1)) == nil) return(nil);

		r = new Vector();
		v = v0;

		for(i = 2; i <= zp.length; i++) {
			e = gateways.getEdge(zp[i - 1], zp[i]);
			e = e.data[1];
			r.appendAll(findPath(v, e.src));
			r.append(e.dst);
			v = e.dst;
		}

		//return(inherited(v0, v1));
		return(r);
	}
;
