#charset "us-ascii"
//
// fastPathZoneVertex.t
//
//	Extension to the FastPathVertex class for vertices in zone-aware
//	graphs.
//	
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathZoneVertex: FastPathVertex
	getFastPathZoneID() { return(data ? data.fastPathZone : nil); }
;
