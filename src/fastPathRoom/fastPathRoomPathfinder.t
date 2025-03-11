#charset "us-ascii"
//
// fastPathRoomPathfinder.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

// Room pathfinder.
// Creating an instance of this class will automagically enable
// cached pathfinding.
class RoomPathfinder: FastPathAutoInit, FastPathMap
	// The kind of object we keep track of.
	fastPathObjectClass = Room

	// The default actor to use for pathfinding.
	fastPathActor = (gameMain.initialPlayerChar)

	fastPathZoneClass = FastPathRoomZone
	fastPathGatewayClass = FastPathRoomGateway

	_fastPathUpdates = perInstance(new Vector())

	// Daemon that looks for updates every turn.
	fastPathDaemon = nil

	// Tweak to the base method.  For room pathfinders we always
	// want an actor defined because pathfinding through rooms
	// depends on the actor.
	createZone(id) {
		local z;

		z = inherited(id);
		z.fastPathActor = fastPathActor;

		return(z);
	}

	// Wrapper around the normal multi-zone pathfinding logic to
	// allow use of rooms as arguments and to return the path as a
	// list of rooms (instead of vertices).
	findPath(v0, v1) {
		local l, r;

		if(isRoom(v0) && ((v0 = roomToVertex(v0)) == nil)) return([]);
		if(isRoom(v1) && ((v1 = roomToVertex(v1)) == nil)) return([]);

		if(!isVertex(v0) || !isVertex(v1)) return([]);

		// Should never happen.
		if((l = findMultiZonePath(v0, v1)) == nil) return([]);

		// Convert the vertices into rooms.
		r = new Vector(l.length());
		l.forEach({ x: r.append(x.data) });

		return(r);
	}

	roomToVertex(rm) {
		local z;
		if(!isRoom(rm)) return(nil);
		if(!rm.fastPathZone || !rm.fastPathID) return(nil);
		if((z = getZone(rm.fastPathZone)) == nil) return(nil);
		return(z.getVertex(rm.fastPathID));
	}

	vertexToRoom(v) {
		if(!isVertex(v)) return(nil);
		if(!isRoom(v.data)) return(nil);
		return(v.data);
	}

	// Hook for FastPathAutoInit class.  Here we 
	initializeFastPath() {
		// Normal initialization.
		initializeFastPathMap();

		// Check the zones created above for disconnected
		// subgraphs.
		verifyFastPathZones();

		fastPathDaemon = new Daemon(self, &updateFastPath, 1);
		fastPathDaemon.eventOrder = 9999;
	}

	// Tweak to testPath() to work with rooms as args.
	testPath(v0, v1, lst) {
		local l;

		// Make sure the list exists and isn't empty.
		if(!lst || !lst.length) return(nil);

		// If the args are rooms convert them into vertices or die
		// trying.
		if(isRoom(v0) && ((v0 = roomToVertex(v0)) == nil)) return(nil);
		if(isRoom(v1) && ((v1 = roomToVertex(v1)) == nil)) return(nil);

		// If the args are IDs, this is where we turn them into
		// vertices.
		if((v0 = resolveVertex(v0)) == nil) return(nil);
		if((v1 = resolveVertex(v1)) == nil) return(nil);

		// Now do the same with the last element of the list.
		l = lst[lst.length];
		if(isRoom(l) && ((l = roomToVertex(l)) == nil)) return(nil);
		if((l = resolveVertex(l)) == nil) return(nil);

		// Destination vertex and last element in the list should
		// match.
		return(v1 == l);
	}

	// Queue a pathfinder update.
	// Arg is either a zone ID, a FastPathZone instance, or a Thing.
	// If the arg is zone-like, then we mark the zone for update.
	// If the arg is a Thing, we get the outermost containing room
	// and add it to the update queue.
	updatePathfinder(v) {
		local z;

		if(isString(v)) {
			// If we got a string, make sure it's a zone ID.
			if((v = canonicalizeZone(v)) == nil) return(nil);

			z = v.fastPathZoneID;	// ID to queue
			v = nil;		// no room
		} else if(isZone(v)) {
			z = v.fastPathZoneID;	// ID to queue
			v = nil;		// no room
		} else {
			// If the arg isn't a zone ID or a Zone instance,
			// it HAS to be a Thing or we give up.
			if(!isThing(v)) return(nil);

			// If it's a non-Room Thing, get the Thing's
			// outermost containing Room.
			if(!isRoom(v) && (v = v.getOutermostRoom()) == nil)
				return(nil);

			// No zone to update--we'll figure out what we
			// need to update based on the location of the
			// room in the graph (only need to update zones
			// when the changed room is on a zone boundary).
			z = nil;
		}

		return(_queueFastPathUpdate(z, v));
	}

	_queueFastPathUpdate(zoneID, rm) {
		local r;

		r = new FastPathUpdate(zoneID, rm);
		_fastPathUpdates.append(r);

		return(r);
	}

	flushFastPathUpdates() {
		local l;

		if(_fastPathUpdates.length() == 0) return;

		// First, update the rooms.
		// Make a unique-ified room list:
		l = new Vector();
		_fastPathUpdates.forEach({ x: l.appendUnique(x.room) });

		// ...and then update each room in it.
		l.forEach({ x: _fastPathUpdateRoom(x) });

		// Flush the vector.
		l.setLength(0);

		// Now go back through the update list, this time
		// createing a unique-ified zone list:
		_fastPathUpdates.forEach({ x: l.appendUnique(x.zoneID) });

		if(l.length < 1) return;

		l.forEach({ x: _fastPathUpdateZone(x) });

		resetFastPathGateways();

		_fastPathUpdates.setLength(0);
	}

	// Figure out what we need to update because a room changed.
	// Because of how we define zones (all rooms in a zone can reach
	// all other rooms in the same zone) we only need to update other
	// zones if the updated room is on a zone boundary (and so maybe
	// the update is due to a door between zones opening or closing).
	_fastPathUpdateRoom(rm0) {
		local b, c, l, v, r, z;

		if(!isRoom(rm0))
			return(nil);

		// Get the the vertex for the zone the room is in.
		if((v = getVertex(rm0.fastPathZone)) == nil)
			return(nil);

		// Make sure the vertex contains a valid zone.
		if(((z = v.data) == nil) || !isZone(z))
			return(nil);

		// Get a list of rooms adjacent to this room that are
		// in a different zone.
		// Return value is a list of Room instances.
		l = z.checkFastPathGateways(rm0);

		// Now get a list of the rooms that WERE adjacent to
		// this room that are in a different zone.
		// If zone reachability hasn't changed this will be the
		// same as l (above).  If something has changed than
		// c will be the current state of the graph, l will
		// be what we need to update it to.
		c = _getGatewaysContaining(rm0);

		// Do we have to update the cache?
		b = nil;

		r = new Vector();

		// Generate a uniquified list of all the newly-adjacent
		// rooms.
		l.forEach(function(rm1) {
			if(c.indexOf(rm1) == nil)
				r.appendUnique(rm1);
		});

		// Create the edges for the newly-created connections.
		r.forEach(function(rm1) {
			local e, v0, v1, z0, z1;

			e = getGateway(rm0.fastPathZone, rm1.fastPathZone);
			if(e == nil)
				e = addGateway(rm0.fastPathZone,
					rm1.fastPathZone);

			if((z0 = getZone(rm0.fastPathZone)) == nil) return;
			if((z1 = getZone(rm1.fastPathZone)) == nil) return;
			if((v0 = z0.canonicalizeVertex(rm0.fastPathID)) == nil)
				return;
			if((v1 = z1.canonicalizeVertex(rm1.fastPathID)) == nil)
				return;

			if(e.getNextHop(v0, v1) != nil) return;
			e.addNextHop(v0, v1);
			b = true;
		});

		// Reset list.
		r.setLength(0);

		// Uniquified list of all the old connections that went away.
		c.forEach(function(rm1) {
			if(l.indexOf(rm1) == nil)
				r.appendUnique(rm1);
		});

		// Go through the list of now-defunct connections and remove
		// their next hop entries.
		r.forEach(function(rm1) {
			local e;

			// Get the edge between the zones.  Remember that
			// there can be more than one--two zones might
			// be connected by multiple connectors.
			e = getEdge(rm0.fastPathZone, rm1.fastPathZone);

			// If the edge doesn't exist we have no idea what's
			// going on and we flee in terror.
			if(e == nil)
				return;

			// We got the edge, so we remove the next hop entry.
			e.removeNextHop(rm0, rm1);

			// If there are no next hops the zones are no longer
			// connected, so we remove the edge.
			if(e.getNextHops().length() == 0)
				removeEdge(rm0.fastPathZone, rm1.fastPathZone);

			// We made an update.
			b = true;
		});

		if(b == true)
			_queueFastPathUpdate(z.fastPathZoneID, nil);

		return(b);
	}

	// Returns a list of rooms adjacent to the given room that are
	// in different zones.
	// If the room isn't on a zone boundary this will produce an
	// empty list.
	_getGatewaysContaining(rm) {
		local l, v;

		if(!isRoom(rm)) return([]);

		if((v = getVertex(rm.fastPathZone)) == nil) return([]);

		l = new Vector();
		v.getEdges().forEach(function(e) {
			e.getNextHops().forEach(function(nh) {
				if(nh.src != rm) return;
				l.append(nh.dst);
			});
		});

		return(l);
	}

	_fastPathUpdateZone(id) {
		local z;

		if((z = getZone(id)) == nil) return(nil);

		z.clearFastPathCache();
		z.createFastPathCache();

		return(true);
	}

	// Called every turn because we're a Schedulable.  Here's where
	// we flush the update cache.
	updateFastPath() {
		flushFastPathUpdates();
	}

	resolveVertex(v) {
		local z;

		if(isRoom(v)) {
			if((z = getZone(v.fastPathZone)) == nil)
				return(nil);
			return(z.resolveVertex(v));
		}

		return(inherited(v));
	}
;
