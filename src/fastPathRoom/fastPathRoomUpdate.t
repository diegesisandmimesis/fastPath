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
		fastPathRoomUpdater.updatePathfinders(self);
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
