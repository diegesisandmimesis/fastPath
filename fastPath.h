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

#define isFastPathGateway(obj) (isType(obj, FastPathGateway))

#define FAST_PATH_H
