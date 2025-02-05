#charset "us-ascii"
//
// fastPathAutoInit.t
//
//	Logic for handling auto-initilizations of pathfinding.
//
//	This is the hook used by room pathfinders to generate graphs
//	of the game map and then to create next hop caches for them, for
//	example.
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

// Mixin for classes that want to be initialized during preinit.
class FastPathAutoInit: object
	initializeFastPath() {}
;

// Singleton that handles pre-init for FastPathPreinit instances.
fastPathAutoInit: PreinitObject
	execBeforeMe = static [ fastPathFilter ]
	execute() {
		local oldSay;

		// This is how we squash output during preinit.
		oldSay = t3SetSay(function(str) {});

		forEachInstance(FastPathAutoInit,
			{ x: x.initializeFastPath() });

		// Restore normal output.
		t3SetSay(oldSay);
	}
;
