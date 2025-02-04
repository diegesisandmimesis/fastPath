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
				_fastPathGatewayQueue.append([ rm0, rm1 ]);
				return;
			}

			// Add the edge.
			addEdge(rm0.fastPathID, rm1.fastPathID);
		});
		
		return(true);
	}
;
