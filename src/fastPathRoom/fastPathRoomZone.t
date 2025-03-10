#charset "us-ascii"
//
// fastPathRoomZone.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathRoomZone: FastPathZone
	fastPathActor = (gameMain.initialPlayerChar)

	// Add the edges associated with this vertex/room.
	addFastPathGateways(v) {
		local rm0;

		// Make sure the arg is valid.  That means it's a vertex
		// and it's data is a room.
		if(!isVertex(v) || !isRoom(v.data))
			return(nil);

		// Iterate over all of this room's exits.
		rm0 = v.data;
		rm0.fastPathDestinationList(fastPathActor)
			.forEach(function(rm1) {

			// If the exit leads to a room in a different zone
			// we do NOT add it as an edge, we just make a note
			// of it for later.
			if(rm1.fastPathZone != fastPathZoneID) {
				queueFastPathGateway([ rm0.fastPathID,
					rm1.fastPathID ]);
				return;
			}

			// Add the edge.
			addEdge(rm0.fastPathID, rm1.fastPathID);
		});
		
		return(true);
	}

	// Given a room, returns a list of the rooms adjacent to it that
	// are in other zones.
	// Return value is a list of Room instances.
	checkFastPathGateways(rm0) {
		local r;

		// Make sure the arg is valid.
		if(!isRoom(rm0)) return([]);

		// For the return value.
		r = new Vector();

		// Traverse the rooms destination list.
		rm0.fastPathDestinationList(fastPathActor)
			.forEach(function(rm1) {
			// If the destination is in the same zone as the
			// argument we don't care about it.
			if(rm1.fastPathZone == fastPathZoneID) return;

			// Add the room to the return list.
			r.append(rm1);
		});

		return(r.toList());
	}

/*
	resetFastPathGateways() {
		getVertices().forEach({ x: resetFastPathGateway(x) });
	}
*/

	resetFastPathGateway(v) {
		local rm0;

		if(!isVertex(v) || !isRoom(v.data))
			return(nil);

		rm0 = v.data;
		rm0.fastPathDestinationList(fastPathActor)
			.forEach(function(rm1) {

			if(rm1.fastPathZone == fastPathZoneID) return;

			queueFastPathGateway([ rm0.fastPathID,
				rm1.fastPathID ]);
		});
		
		return(true);
	}

	roomToVertex(rm) {
		if(!isRoom(rm)) return(nil);
		return(getVertex(rm.fastPathID));
	}

	canonicalizeVertex(v) {
		if(isRoom(v)) return(inherited(v.fastPathID));
		return(inherited(v));
	}
;
