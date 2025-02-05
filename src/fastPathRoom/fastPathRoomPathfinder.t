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

	createZone(id) {
		local z;

		z = inherited(id);
		z.fastPathActor = fastPathActor;

		return(z);
	}

	updatePathfinder(obj) {}

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
		initializeFastPathMap();
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
;
