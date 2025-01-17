#charset "us-ascii"
//
// fastPathRoom.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

modify Room
	fastPathZone = nil		// zone ID.  can be set in source, or
					// automagically assigned by pathfinder

	fastPathID = nil		// vertex ID assigned by pathfinder
	fastPathVertex = nil		// vertex assigned by pathfinder

	// Method to enumerate all of the destinates reachable, by the
	// given actor, from this room.
	fastPathDestinationList(actor?, cb?) {
		local c, dst, r;

		r = new Vector(Direction.allDirections.length());

		if((actor = (actor ? actor : gActor)) == nil) return(r);

		Direction.allDirections.forEach(function(d) {
			if((c = getTravelConnector(d, actor)) == nil)
				return;
			if(!c.isConnectorApparent(self, actor))
				return;
			if((dst = c.getDestination(self, actor)) == nil)
				return;
			if((cb != nil) && ((cb)(d, dst) != true))
				return;
			r.append(dst);
		});

		return(r);
	}
;

// Room pathfinder.
// Creating an instance of this class will automagically enable
// cached pathfinding.
class RoomPathfinder: FastPathMap, FastPathPreinit
	// The kind of object we keep track of.
	fastPathObjectClass = Room

	// The default actor to use for pathfinding.
	fastPathDefaultActor = (gameMain.initialPlayerChar)

	// Associate a room with a zone.
	fastPathGrouper(obj) {
		if(!isRoom(obj)) return(nil);
		return(new FastPathGroup(
			getFastPathZone(obj),
			//(obj.fastPathZone ? obj.fastPathZone : 'default'),
			getFastPathID(obj)));
			//(obj.fastPathID ? obj.fastPathID : obj.name)));
		//return(inherited(obj));
	}
/*
	fastPathGrouper(obj) {
		if(!isRoom(obj)) return(nil);
		return(inherited(obj));
	}
*/

	fastPathAddEdges(obj, actor?) {
		if(!isVertex(obj) || !isRoom(obj.data)) return;
		actor = (actor ? actor : fastPathDefaultActor);
		obj.data.fastPathDestinationList(actor).forEach({ rm:
			addEdge(obj.vertexID,
				(rm.fastPathID ? rm.fastPathID : rm.name))
		});
	}

	findPath(v0, v1) {
		local l, r;

		if(isRoom(v0) && v0.fastPathVertex) v0 = v0.fastPathVertex;
		if(isRoom(v1) && v1.fastPathVertex) v1 = v1.fastPathVertex;

		l = findPathWithZones(v0, v1);

		r = new Vector(l.length());
		l.forEach({ x: r.append(x.data) });

		return(r);
	}

	testPath(v0, v1, lst) {
		if(!lst || !lst.length) return(nil);
		if(!isRoom(v1)) {
			v1 = canonicalizeVertex(v1);
			if(isVertex(v1)) v1 = v1.fastPathVertex;
		}
		return(lst[lst.length()] == v1);
	}
;
