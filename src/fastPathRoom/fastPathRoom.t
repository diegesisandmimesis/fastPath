#charset "us-ascii"
//
// fastPathRoom.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

modify Room
	fastPathID = nil		// vertex ID assigned by pathfinder

	fastPathZone = nil		// zone ID.  can be set in source, or
					// automagically assigned by pathfinder

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

			if(!_checkFastPathConnector(actor, c, dst))
				return;

			if((cb != nil) && ((cb)(d, dst) != true))
				return;

			r.append(dst);
		});

		return(r);
	}

	_checkFastPathConnector(actor, conn, dst) {
		local f, r, tr;

		tr = gTranscript;
		f = fastPathFilter.active;

		try {
			savepoint();

			gTranscript = new CommandTranscript();
			fastPathFilter.active = true;

			actor.moveInto(self);
			newActorAction(actor, TravelVia, conn);

			if(actor.location == dst)
				r = true;
		}

		catch(Exception e) {
			r = nil;
		}

		finally {
			undo();
			gTranscript = tr;
			fastPathFilter.active = f;
			return(r == true);
		}
	}
;

fastPathFilter: OutputFilter, PreinitObject
	active = nil
	filterText(str, val) { return(active ? '' : inherited(str, val)); }
	execute() { mainOutputStream.addOutputFilter(self); }
;
