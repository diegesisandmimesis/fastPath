# fastPath

A TADS3/adv3 module implementing pathfinding via precomputed tables.

## Description

## Table of Contents

[Getting Started](#getting-started)
* [Dependencies](#dependencies)
* [Installing](#install)
* [Compiling and Running Demos](#running)

[Classes](#classes)
* [Graph-Related Classes](#graph-section)
  * [FastPathGraph](#fast-path-graph)
  * [FastPathVertex](#fast-path-vertex)
  * [FastPathEdge](#fast-path-edge)
* [Zone-Related Classes](#zone-section)
  * [FastPathGateway](#fast-path-gateway)
  * [FastPathGatewayPick](#fast-path-gateway-pick)
  * [FastPathGroup](#fast-path-group)
  * [FastPathZone](#fast-path-zone)
* [Room Pathfinder](#room-section)
  * [RoomPathfinder](#room-pathfinder)

<a name="getting-started"/></a>
## Getting Started

<a name="dependencies"/></a>
### Dependencies

* TADS 3.1.3
* adv3 3.1.3

  These are the most recent versions of the TADS3 VM and adv3 library.

  Any TADS3 toolkit with these versions should work, although all of the
  [diegesisandmimesis](https://github.com/diegesisandmimesis) modules are
  primarily tested with [frobTADS](https://github.com/realnc/frobtads).

* git

  This module is distributed via github, so you'll need some way of
  cloning a git repo to obtain it.

  The process should be similar on any platform using any tools, but the
  command line examples given below were tested on an Ubuntu linux
  machine.  Other OSes and git tools will have a slightly different usage.

<a name="install"/></a>
### Installing

All of the [diegesisandmimesis](https://github.com/diegesisandmimesis) modules
are designed to be installed and used from a common base install directory.

In this example we'll use ``/home/username/tads`` as the base directory.

* Create the module base directory if it doesn't already exists:

  `mkdir -p /home/username/tads`

* Make it the current directory:

  ``cd /home/username/tads``

* Clone this repo:

  ``git clone https://github.com/diegesisandmimesis/fastPath.git``

After the ``git`` command, the module source will be in
``/home/username/tads/fastPath``.

<a name="running"/></a>
### Compiling and Running Demos

Once the repo has been cloned you should be able to ``cd`` into the
``./demo/`` subdirectory and compile the demonstration/test code that
comes with the module.

All the demos are structured in the expectation that they will be compiled
and run from the ``./demo/`` directory.  Again assuming that the module
is installed in ``/home/username/tads/fastPath/``, enter the directory with:
```
# cd /home/username/tads/fastPath/demo
```
Then make one of the demos, for example:
```
# make -a -f FIXME.t3m
```
This should produce a bunch of output from the compiler but no errors.  When
it is done you can run the demo from the same directory with:
```
# frob games/FIXME.t3
```
In general the name of the makefile and the name of the compiled story file
will be the same except for the extensions (``.t3m`` for makefiles and
``.t3`` for story files).

<a name="classes"/></a>
## Classes

<a name="graph-section"/></a>
### Graph-Related Classes

<a name="fast-path-graph"/></a>
#### FastPathGraph

##### Properties

* ``autoCreateFastPathCache = true``

  If ``true``, cache will be created if it doesn't already exist.

* ``vertexClass = FastPathVertex``

  ``edgeClass = FastPathEdge``

  Base classes for vertices and edges, respectively.

##### Methods

* ``clearFastPathCache()``

  Clear the next hop cache on all vertices in the graph.

* ``createFastPathCache()``

  Generate the next hop tables for every vertex in the graph.

* ``clearFastPathCache()``

  Clear the next hop cache on all vertices in the graph.

* ``resetFastPathCache()``

  Clear and then re-create next hop cache for the graph.

* ``getFastPath(vertex0, vertex1)``

  Returns the next hop in the path from the first argument to the second.

  Arguments can be vertex IDs or ``Vertex`` instances.

* ``findPathInSingleZone(vertex0, vertex1)``

  Returns an array in which each element is a vertex in the path between the
  first argument and the second.

  This method only uses a single zone.  That is, it assumes all vertices are
  in a single set of next hop tables.

  Arguments can be vertex IDs or ``Vertex`` instances.

* ``findPath(vertex0, vertex1)``

  Returns an array in which each element is a vertex in the path between the
  first argument and the second.

  By default this is just a wrapper for ``findPathInSingleZone()``, but
  subclasses may implement different pathfinding schemes.

  Arguments can be vertex IDs or ``Vertex`` instances.

* ``testPath(vertex0, vertex1, path)``

  Given two vertices and an array, returns boolean ``true`` if the last
  element in the array is the second vertex.

  Provided as a very simple check against computed paths.

<a name="fast-path-vertex"/></a>
#### FastPathVertex

##### Properties

* ``data = nil``

  Per-vertex user data.  In the room pathfinder this is a pointer to the
  ``Room`` the vertex represents, for example.

* ``fastPathCache = perInstance(new LookupTable())``

  ``LookupTable`` containing the next hop data for this vertex.

* ``fastPathCacheDirty = true``

  Boolean flag.  If ``true`` it indicates that the cache is invalid and needs to
  be re-created.

##### Methods

* ``getFastPath(vertex)``

  Returns the next hop to reach the given destination vertex.

  Argument can be a vertex ID or a ``Vertex`` instance.

* ``setFastPath(dstVertex, adjacentVertex)``

  Adds an entry to the next hop cache.  First arg is the destination vertex,
  second arg is the adjacent vertex that leads to it.

  First argument can be either a vertex ID or a ``Vertex`` instance.  **Second
  argument must be a ``Vertex`` instance**.

* ``clearFastPathCache()``

  Clears this vertex's next hop cache.


<a name="fast-path-edge"/></a>
#### FastPathEdge

##### Properties

* ``data = nil``

  Per-edge user data.  Used in zone-away pathfinders to hold gateway data.

<a name="zone-section"/></a>
### Zone-Related Classes

<a name="fast-path-gateway"/></a>
#### FastPathGateway

The ``FastPathGateway`` path is a simple data structure that provides
additional information about edges in the zone graph.  Specifically they
describe a pair of vertices in the main graph that connect two zones.

Every zone-aware pathfinder consists of two graphs:  the main graph and the
zone graph.  If the pathfinder is for the game map, for example, the main
graph will have a vertex for each room and an edge for each room connection.
The rooms will each have a zone ID, and the zone graph will describe
how the zones are connected to each other.  In this situation, each
``FastPathGateway`` would include a pair of rooms that connect two zones.

##### Properties

* ``src = nil``

 The near side vertex in the main graph.

* ``dst = nil``

  The far side vertex in the main graph.

<a name="fast-path-gateway-pick"/></a>
#### FastPathGatewayPick

A data structure containing the outcome of a gateway choice.  Returned by
``FastPathZone.pickGateway()``.

##### Properties

* ``nextHop = nil``

  The next hop *after* the path through the zone.  This will be the far side
  vertex from the gateway table entry.

* ``pathThroughZone = nil``

  The path through the zone via the selected gateway.

<a name="fast-path-group"/></a>
#### FastPathGroup

<a name="fast-path-zone"/></a>
#### FastPathZone


<a name="room-section"/></a>
### Room Pathfinder

<a name="room-pathfinder"/></a>
#### RoomPathfinder
