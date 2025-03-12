//
// fastPath.h
//

#include "dataTypes.h"
#ifndef DATA_TYPES_H
#error "This module requires the dataTypes module."
#error "https://github.com/diegesisandmimesis/dataTypes"
#error "It should be in the same parent directory as this module.  So if"
#error "fastPath is in /home/user/tads/fastPath, then"
#error "dataTypes should be in /home/user/tads/dataTypes ."
#endif // DATA_TYPES_H

#define isGateway(obj) (isType(obj, FastPathGateway))
#define isMap(obj) (isType(obj, FastPathMap))
#define isZone(obj) (isType(obj, FastPathZone))

#define gUpdateFastPath(obj) (fastPathRoomUpdater.updatePathfinders(obj))

#define FAST_PATH_H
