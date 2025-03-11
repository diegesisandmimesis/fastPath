#charset "us-ascii"
//
// fastPathRoomGateway.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

// Kinda worthless, but we ad a subclass in case somebody else
// wants to make changes ONLY to the room gateway class.
class FastPathRoomGateway: FastPathGateway;
