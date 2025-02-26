#charset "us-ascii"
//
// fastPathMap.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathMap: FastPathGraph
	fastPathBaseID = 'fastPath'
	fastPathDefaultZone = 'default'

	fastPathObjectClass = nil

	fastPathZoneClass = FastPathZone
	fastPathGatewayClass = FastPathGateway

	edgeClass = (fastPathGatewayClass)

	_fastPathIDCounter = 0

	//fastPathZoneTable = perInstance(new LookupTable())

	initializeFastPathMap() {
		if(fastPathObjectClass == nil)
			return;

		// First pass:  we create all the vertices.
		forEachInstance(fastPathObjectClass,
			{ x: initializeFastPathObject(x) });

		// Second pass:  we create all the "normal" edges inside
		//	each zone.  We do this in a second pass (instead of
		//	adding edges as we create the vertices) because
		//	there's much less bookeeping if we don't create
		//	new vertices in the middle of creating edges.
		getZones().forEach({ x: x.flushFastPathVertexQueue() });

		// Third pass:  in the second pass each zone created a
		//	list of edges that would cross zone boundaries.
		//	we now go back and add them as gateways, edges
		//	on our zone graph.
		getZones().forEach({ x: flushFastPathGatewayQueue(x) });
	}

	flushFastPathGatewayQueue(z0) {
		local g, v0, v1, z1;

		// Traverse this zone's gateway queue.  The queue is an
		// array whose elements are arrays themselves, each one
		// containing two elements:  a room in this zone, and
		// the connecting room in a different zone.
		z0.getFastPathGatewayQueue().forEach(function(l) {
			// We know the first vertex is in the current zone,
			// so we call its canonicalizeVertex() method instead
			// of using the slightly more expensive resolveVertex().
			if((v0 = z0.canonicalizeVertex(l[1])) == nil) return;

			// Second vertex will NOT be in this zone, so we
			// need to query all zones.
			if((v1 = resolveVertex(l[2])) == nil) return;

			// Get the other zone.
			if((z1 = getZone(v1.getFastPathZoneID())) == nil)
				return;

			// This is the edge connecting the two zones.
			g = addGateway(z0.fastPathZoneID, z1.fastPathZoneID);

			// This is extra data added to the edge, describing
			// which vertices connect the two zones.  Note that
			// there can be multiple connections like this.
			g.addNextHop(v0, v1);
		});
		
		z0.flushFastPathGatewayQueue();
	}

	// Add an object to whatever zone it belongs to, creating the
	// zone if it doesn't already exists.
	initializeFastPathObject(obj) {
		local z;

		if((obj == nil) || !obj.ofKind(fastPathObjectClass))
			return(nil);

		// First thing we do is make sure the object has a vertex ID
		// and a zone ID.
		assignFastPathID(obj);
		assignFastPathZone(obj);

		if((z = getZone(obj.fastPathZone)) == nil)
			z = createZone(obj.fastPathZone);

		z.queueFastPathVertex(obj);

		return(true);
	}

	createZone(id) {
		local z;

		z = addZone(id);
		z.fastPathZoneID = id;
		z.fastPathObjectClass = fastPathObjectClass;

		return(z);
	}

	// Assign a vertex ID to the given object.
	// NOTE:  This vertex ID needs to be unique-ish across the GAME, not
	// 	just this GRAPH.  Because a single object may be in multiple
	//	graphs, and it will always use the same vertex ID.
	assignFastPathID(obj) {
		if((obj == nil) || !obj.ofKind(fastPathObjectClass))
			return(nil);
		if(obj.fastPathID) return(nil);

		_fastPathIDCounter += 1;
		obj.fastPathID = fastPathBaseID + toString(_fastPathIDCounter);

		return(true);
	}

	// Assign a zone ID to the given object.
	// NOTE:  The zone ID needs to be unique-ish across the GAME, not
	//	just this GRAPH.  Because a single object may be in multiple
	//	graphs, and it will always use the same zone ID.
	assignFastPathZone(obj) {
		if((obj == nil) || !obj.ofKind(fastPathObjectClass))
			return(nil);
		if(obj.fastPathZone) return(nil);

		obj.fastPathZone = fastPathDefaultZone;

		return(true);
	}

	// Convenience methods for zones.
	addZone(id, obj?) {
		local v;

		v = addVertex(id, obj);
		v.data = fastPathZoneClass.createInstance(id);

		return(v.data);
	}

	getZone(id) {
		local z;

		if(isZone(id)) id = id.fastPathZoneID;
		if((z = getVertex(id)) == nil) return(nil);
		return(z.data);
	}

	removeZone(id) {
		local z;

		if((z = getVertex(id)) == nil) return(nil);
		if(z.data != nil)
			z.data.removeVertices();
		
		return(removeVertex(id));
	}

	getZones() {
		local l;

		l = new Vector();
		getVertices().forEach({ x: l.append(x.data) });
		return(l);
	}

	// Convenience methods for gateways.
	addGateway(id0, id1, obj?) { return(addEdge(id0, id1, obj)); }
	getGateway(id0, id1) { return(getEdge(id0, id1)); }
	removeGateway(id0, id1) { return(removeEdge(id0, id1)); }
	getGateways() { return(getEdges()); }

	canonicalizeZone(z) {
		if(z == nil) return(nil);
		if(z.ofKind(FastPathZone)) return(getZone(z.fastPathZoneID));
		return(getZone(z));
	}

	// Like canonicalizeVertex(), but we search all our zones for the
	// vertex instead of just checking ourselves.
	resolveVertex(v) {
		local i, l, r;
		if(isVertex(v)) return(v);
		l = getZones();
		for(i = 1; i <= l.length; i++)
			if((r = l[i].getVertex(v)) != nil) return(r);

		return(nil);
	}

	// Replacement for the stock method, which just checks a single zone.
	findPath(v0, v1) { return(findMultiZonePath(v0, v1)); }

	// Zone-aware pathfinding algorithm.
	findMultiZonePath(v0, v1) {
		local d0, d1, g, i, p, r, v, z0, z1, zp;

		// If the args aren't valid, return an empty path.
		if((v0 = resolveVertex(v0)) == nil) return([]);
		if((v1 = resolveVertex(v1)) == nil) return([]);

		// If either of the vertices lack a .data property, they're
		// not zone routable, fail.
		if(((d0 = v0.data) == nil) || ((d1 = v1.data) == nil))
			return([]);

		// If the start and end points are both in the same zone,
		// get the zone and it handles the entire pathfinding
		// process.
		if(d0.fastPathZone == d1.fastPathZone) {
			// Make sure we have a valid zone.
			if((z0 = getZone(d0.fastPathZone)) == nil)
				return([]);

			// Call the zone's pathfinder.
			return(z0.findPath(v0, v1));
		}

		// Make sure we have zones for the zone IDs on the
		// source and destination vertices.
		if((z0 = getVertex(d0.fastPathZone)) == nil) return([]);
		if((z1 = getVertex(d1.fastPathZone)) == nil) return([]);

		// We now get the zone path--the list of zones we need
		// to traverse in order to reach the destination.
		zp = findSingleZonePath(z0.vertexID, z1.vertexID);

		// If the zone path doesn't have at least two zones, we're
		// borked;  we already check above to see if the endpoints
		// are in the same zone and if we're here they're not.  So
		// if the zone path is less than two zones long we don't
		// know how to pathfind between the two endpoints.
		if(zp.length < 2) return([]);

		// Results vector.  This will hold the full path.
		r = new Vector();

		// Current vertex.
		v = v0;

		// We pairwise traverse the zone path, starting with
		// the first two, then the second and third, then
		// third and fourth, and so on.
		for(i = 2; i <= zp.length; i++) {
			// Get the gateway between the two zones we're
			// currently considering.
			// If we don't know about a gateway between them
			// then we fail, returning the path so far.
			if((g = getGateway(zp[i - 1], zp[i])) == nil)
				return(r);

			// Figure out which connection between the two
			// zones we want to path through.  The return
			// value will be a data structure containing the
			// path through the first zone from the current
			// vertex to the connection to the second zone.
			p = pickNextHop(zp[i - 1].data, g, v);

			// Add the path through the first zone to the
			// results list.
			r.appendAll(p.pathThroughZone);

			// Make the current vertex the next hop.  That
			// will be the room in the second zone that connects
			// to the first zone.
			v = p.nextHop;
		}

		// Above we traverse all the gateways in the zone path,
		// but this can leave us without the path through the
		// last zone.
		// We check to see if z, which is the vertex we've
		// pathed up to, is the destination vertex.  If so,
		// we can just add it to the results list and we're done.
		// If it isn't, we get the last zone in the zone path list,
		// and then use it to get the path across the last zone,
		// which should complete the path.
		if(v != v1) {
			if((g = getZone(zp[zp.length].vertexID)) != nil)
				r.appendAll(g.findSingleZonePath(v, v1));
		} else {
			r.append(v);
		}
		

		return(r);
	}

	pickNextHop(z, g, v) {
		local i, l, lst, pick, shortPath;

		shortPath = nil;
		pick = nil;

		v = z.getVertex(v.vertexID);

		lst = g.getNextHops();
		for(i = 1; i <= lst.length(); i++) {
			l = z.findPath(v, lst[i].src);
			if((pick == nil) || (shortPath.length > l.length)) {
				shortPath = l;
				pick = lst[i];
			}
		}

		return(new FastPathNextHopPick(pick.dst, shortPath));
	}

	// Tweak to testPath() to use zone-aware vertex canonicalization.
	testPath(v0, v1, lst) {
		if(!lst || !lst.length) return(nil);
		return(resolveVertex(v1) == resolveVertex(lst[lst.length]));
	}

	resetFastPath() {
		getZones().forEach({ x: x.resetFastPathGateways() });
		getZones().forEach({ x: flushFastPathGatewayQueue(x) });
		getZones().forEach({ x: resetFastPathZone(x) });

		clearFastPathCache();
		createFastPathCache();
	}

	resetFastPathZone(z) {
		if((z = canonicalizeZone(z)) == nil) return(nil);

		z.clearFastPathCache();
		z.createFastPathCache();

		return(true);
	}

	// Go through all the current zones checking for disconnected
	// subgraphs.
	verifyFastPathZones() {
		getZones().forEach({ x: verifyFastPathZone(x.fastPathZoneID) });
	}

	// Check the given zone for disconnected subgraphs, fixing them
	// if necessary.
	verifyFastPathZone(zoneID?) {
		// Figure out which zone we're looking at.
		zoneID = (zoneID ? zoneID : fastPathDefaultZone);

		if(!fixFastPathSubgraphs(zoneID))
			return(nil);

		getZones().forEach({ x: x.resetFastPathGateways() });
		getZones().forEach({ x: flushFastPathGatewayQueue(x) });
		getZones().forEach({ x: resetFastPathZone(x) });
		clearFastPathCache();

		removeVertices();

		initializeFastPathMap();

		getZones().forEach({ x: x.createFastPathCache() });
		createFastPathCache();

		return(true);
	}

	// Check a zone for isolated subgraphs, re-rolling them into
	// their own zones if there are any.
	// Arg is the zone ID, defaulting to the "default" zone if none
	// is given.
	fixFastPathSubgraphs(zoneID?) {
		local i, id, l, z;

		// Figure out which zone we're looking at.
		zoneID = (zoneID ? zoneID : fastPathDefaultZone);

		// If the zone doesn't exist, nothing to do.
		if((z = getZone(zoneID)) == nil)
			return(nil);

		// generateSubgraphs() should never return nil so this
		// should never happen.
		if((l = z.generateSubgraphs()) == nil)
			return(nil);

		// If there are zero or one subgraphs then we don't have
		// anything to fix.
		if(l.length < 2)
			return(nil);

		// Iterate over all the subgraphs.
		for(i = 1; i <= l.length; i++) {
			id = _getFastPathSubgraphID(zoneID, i);

			l[i].forEach(function(v) {
				if((v = z.canonicalizeVertex(v)) == nil)
					return;
				if(v.data == nil)
					return;
				v.data.fastPathZone = id;
			});
		}

		return(true);
	}

	// Method used to generate zone IDs for new zones created to
	// eliminated isolated subgraphs.
	_getFastPathSubgraphID(baseID, idx) {
		local id, n, z;

		// First guess:  just the base name plus an index.
		id = baseID + toString(idx);

		// Counter for retries.
		n = 0;

		// Iterate as long as the ID is for an existing zone.
		z = getZone(id);
		while(z != nil) {
			// Increment the counter.
			n += 1;

			// Add the counter as a suffix to the ID.
			id = baseID + toString(idx) + '-' + toString(n);

			// Try again.
			z = getZone(id);
		}

		// Return the first ID we tried that doesn't correspond
		// to an existing zone.
		return(id);
	}
;
