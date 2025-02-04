#charset "us-ascii"
//
// fastPathGroup.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

/*
// Data structure consisting of a zoneID and a vertexID.  This is used
// by fastPathGroup(), which takes object instances (for example rooms)
// and figures out what zone they belong in and what vertex ID to use
// for them.
// A zone in this usage is just a subgraph that gets its own lookup table
// for path finding.
class FastPathGroup: object
	zoneID = nil
	vertexID = nil
	construct(v0?, v1?) {
		zoneID = v0;
		vertexID = v1;
	}
;
*/
