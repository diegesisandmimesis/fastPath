#charset "us-ascii"
//
// fastPathPreinit.t
//
//	Here we handle the logic for treating other object classes--like
//	rooms--as vertices in a graph.
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

// Singleton that handles pre-init for FastPathPreinit instances.
// We don't just add PreinitObject to FastPathPreinit itself because
// to avoid collisions with other stuff already using execute().  Basically
// the whole point of FastPathPreinit is to act as a graph layer on top
// of existing kinds of objects, and they might already have their
// own execute() methods.
fastPathInit: PreinitObject
	execBeforeMe = static [ fastPathFilter ]
	execute() {
		local oldSay;

		// This is how we squash output during preinit.
		oldSay = t3SetSay(function(str) {});

		forEachInstance(FastPathPreinit, { x: x.initializeFastPath() });

		// Restore normal output.
		t3SetSay(oldSay);
	}
;

// Just a mixin for pathfinders that want preinit.
class FastPathPreinit: object initializeFastPath() {};
