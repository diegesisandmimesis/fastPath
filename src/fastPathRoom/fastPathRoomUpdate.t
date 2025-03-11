#charset "us-ascii"
//
// fastPathRoomUpdate.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

// Singleton that handles updating all room pathfinders.
fastPathRoomUpdater: object
	updatePathfinders(obj) {
		forEachInstance(RoomPathfinder, { x: x.updatePathfinder(obj) });
	}
;

// Tweak lockable objects to update the pathfinder.
modify Lockable
	makeLocked(stat) {
		inherited(stat);

		// If we're not a travel connector (a treasure chest
		// or a desk or something) then we don't need to
		// update any pathfinders.
		if(!ofKind(TravelConnector))
			return;

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

// Data structure for pathfinder updates.
// Indicates the room and zone where the update happened, which is
// used to figure out which bits of cached pathfinding data need to
// be updated.
class FastPathUpdate: object
	zoneID = nil
	room = nil
	construct(v0?, v1?) {
		zoneID = v0;
		room = v1;
	}
;
