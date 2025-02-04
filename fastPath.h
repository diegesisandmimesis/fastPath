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

#include "asyncEvent.h"
#ifndef ASYNC_EVENT_H
#error "This module requires the asyncEvent module."
#error "https://github.com/diegesisandmimesis/asyncEvent"
#error "It should be in the same parent directory as this module.  So if"
#error "fastPath is in /home/user/tads/fastPath, then"
#error "asyncEvent should be in /home/user/tads/asyncEvent ."
#endif // ASYNC_EVENT_H

#define isGateway(obj) (isType(obj, FastPathGateway))
#define isMap(obj) (isType(obj, FastPathMap))
#define isZone(obj) (isType(obj, FastPathZone))

#define FAST_PATH_H
