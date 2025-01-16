#charset "us-ascii"
//
// fastPathRoom.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class RoomPathfinder: FastPathPreinit
	fastPathObjectClass = Room

	fastPathGrouper(obj) {
		if(!isRoom(obj)) return(nil);
		return(new FastPathGroup(
			(obj.fastPathZone ? obj.fastPathZone : 'default'),
			(obj.fastPathID ? obj.fastPathID : obj.name)));
	}

	fastPathAddEdges(obj) {
		if(!isVertex(obj) || !isRoom(obj.data)) return;
		obj.data.destinationList(me).forEach(function(rm) {
			addEdge(obj.vertexID,
				(rm.fastPathID ? rm.fastPathID : rm.name));
		});
	}
;
