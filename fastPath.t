#charset "us-ascii"
//
// fastPath.t
//
//	A TADS3/adv3 module implementing pathfinding via pre-computed
//	lookup tables.
//
//	For most purposes just adding something like:
//
//		pathfinder: RoomPathfinder;
//
//	to the game source will be sufficient.
//
//	For more detailed usage information, including performance tweaks
//	and optimizations, check the README.
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

// Module ID for the library
fastPathModuleID: ModuleID {
        name = 'Fast Path Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}
