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

	fastPathDestinationList(actor?, cb?) {
		local c, dst, r;

		r = new Vector(Direction.allDirections.length());

		actor = (actor ? actor : gActor);
		if(!actor) return(r);

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

class RoomPathfinder: FastPathPreinit
	fastPathObjectClass = Room
	fastPathDefaultActor = (gameMain.initialPlayerChar)

	fastPathGrouper(obj) {
		if(!isRoom(obj)) return(nil);
		return(new FastPathGroup(
			(obj.fastPathZone ? obj.fastPathZone : 'default'),
			(obj.fastPathID ? obj.fastPathID : obj.name)));
	}

	fastPathAddEdges(obj, actor?) {
		if(!isVertex(obj) || !isRoom(obj.data)) return;
		actor = (actor ? actor : fastPathDefaultActor);
		obj.data.fastPathDestinationList(actor).forEach({ rm:
			addEdge(obj.vertexID,
				(rm.fastPathID ? rm.fastPathID : rm.name))
		});
	}
;
