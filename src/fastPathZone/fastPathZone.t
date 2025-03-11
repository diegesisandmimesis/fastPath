#charset "us-ascii"
//
// fastPathZone.t
//
//	A "zone" in our usage is a subgraph, typically one that is either
//	disconnected from the rest of the graph, or which is only connected
//	by a few edges.
//
//	The specific design case is handling the overall game map, in which
//	distinct areas of the map are zones.
//
//	The functional purpose of zones is to delineate chunks of map
//	in which all the rooms in the zone are always rechable from every
//	other room in the zone, to make caching pathfinding data easier.
//	
//
#include <adv3.h>
#include <en_us.h>

#include "fastPath.h"

class FastPathZone: FastPathGraph
	fastPathObjectClass = nil
	fastPathZoneID = nil

	vertexID = (fastPathZoneID)
	vertexClass = FastPathZoneVertex

	_fastPathGatewayQueue = perInstance(new Vector())

	// Queue for vertices we've added but whose edges we haven't
	// figured out yet.
	_fastPathVertexQueue = perInstance(new Vector())

	construct(id?) {
		if(id != nil) fastPathZoneID = id;
	}

	// Add an object as a vertex and add it to the queue.
	// The queue is to remind us that we have to figure out the
	// new vertex's edges, which we don't do immediately because
	// subclasses might have to do a lot of elaborate gymnastics
	// for this step.
	queueFastPathVertex(obj) {
		local v;

		if((obj == nil) || !obj.ofKind(fastPathObjectClass))
			return(nil);

		if(obj.fastPathID == nil)
			return(nil);

		if(getVertex(obj.fastPathID))
			return(nil);

		v = addVertex(obj.fastPathID);
		v.data = obj;

		_fastPathVertexQueue.append(v);

		return(true);
	}

	// Go through the vertex queue and figure out the edges.
	flushFastPathVertexQueue() {
		_fastPathVertexQueue.forEach({ x: addFastPathGateways(x) });
	}

	// Stub method;  each subclass needs to implement its own method
	// for figuring out how its object type is connected.
	addFastPathGateways(v) {
		if(!isVertex(v))
			return(nil);

		return(true);
	}

	getFastPathGatewayQueue() { return(_fastPathGatewayQueue); }
	queueFastPathGateway(v) { _fastPathGatewayQueue.append(v); }
	flushFastPathGatewayQueue() { _fastPathGatewayQueue.setLength(0); }

	resetFastPathGateways() {
		getVertices().forEach({ x: resetFastPathGateway(x) });
	}
	resetFastPathGateway(v) { addFastPathGateways(v); }
;
