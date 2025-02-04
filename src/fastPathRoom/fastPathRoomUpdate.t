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
