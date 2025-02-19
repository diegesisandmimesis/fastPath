#charset "us-ascii"
//
// fastPathRoomUpdate.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

fastPathRoomUpdater: object
	updatePathfinders(obj) {
		forEachInstance(RoomPathfinder, { x: x.updatePathfinder(obj) });
	}
;

modify Lockable
	makeLocked(stat) {
		inherited(stat);

		// We always have to update our location.
		fastPathRoomUpdater.updatePathfinders(self);

		// If we're the "main" door we also have to update the
		// "other" side.  If we're the "other" side we also
		// have to update the "main" side.
		// This is because a door is normally locked or unlocked
		// by just calling this method on one half of the door
		// pair--so the other half's makeLocked() method won't
		// get called, so we can't just use the line above by
		// itself.
		if(masterObject == self)
			fastPathRoomUpdater.updatePathfinders(otherSide);
		else
			fastPathRoomUpdater.updatePathfinders(masterObject);
	}
;

class FastPathUpdate: object
	zoneID = nil
	room = nil
	construct(v0?, v1?) {
		zoneID = v0;
		room = v1;
	}
;
