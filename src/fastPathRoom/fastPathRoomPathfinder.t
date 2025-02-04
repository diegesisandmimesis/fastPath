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
class RoomPathfinder: FastPathMap
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

	findPath(v0, v1) {
		local l, r;

		if(isRoom(v0) && ((v0 = roomToVertex(v0)) == nil)) return([]);
		if(isRoom(v1) && ((v1 = roomToVertex(v1)) == nil)) return([]);

		if(!isVertex(v0) || !isVertex(v1)) return([]);

		l = inherited(v0, v1);

		r = new Vector(l.length());
		l.forEach({ x: r.append(x. data) });

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
;
