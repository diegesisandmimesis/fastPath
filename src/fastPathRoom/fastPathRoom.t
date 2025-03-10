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

			if((cb != nil) && ((cb)(actor, c, d, dst) != true))
				return;

			r.append(dst);
		});

		return(r);
	}

	_checkFastPathConnector(actor, conn, dst) {
#ifndef FAST_PATH_TRY_CATCH
		local i, l;

		if(!actor.canTravelVia(conn, dst)) return(nil);
		if(!conn.canTravelerPass(actor)) return(nil);
		l = conn.travelBarrier;
		if(!isCollection(l)) l = [ l ];
		for(i = 1; i <= l.length; i++) {
			if(!l[i].canTravelerPass(actor))
				return(nil);
		}

		if(!conn.fastPathPassable(actor, dst))
			return(nil);

		return(true);
#else // FAST_PATH_TRY_CATCH
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
#endif // FAST_PATH_TRY_CATCH
	}

;

modify TravelConnector
	fastPathPassable(actor, dst?) {
		if(!ofKind(BasicOpenable))
			return(true);
		if(isOpen())
			return(true);
		if(!ofKind(Lockable))
			return(true);
		if(!isLocked())
			return(true);
		return(nil);
	}
;

fastPathFilter: OutputFilter, PreinitObject
	active = nil
	filterText(str, val) { return(active ? '' : inherited(str, val)); }
	execute() { mainOutputStream.addOutputFilter(self); }
;
