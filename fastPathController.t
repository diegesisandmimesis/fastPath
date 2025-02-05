#charset "us-ascii"
//
// fastPathController.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

fastPathController: object
	_uidCounter = 0

	getFastPathVertexID() {
		_uidCounter += 1;
		return('fastPathVertex' + toString(_uidCounter));
	}
;
