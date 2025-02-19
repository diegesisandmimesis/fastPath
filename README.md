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

[Examples](#examples)
* [Generic Pathfinding](#generic)
* [Room Pathfinding](#room)

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

<a name="methods-note"/></a>
**NOTE**

There are numerous methods that provide low-level ways to manipulate the
cache used for pathfinding.  **In general they should not be used** and
cache manipulation should be handled by ``resetFastPath()`` (or
subclass-specific methods, like ``RoomPathfinder.updatePathfinder()``.

* ``clearFastPathCache()``

  Clear the next hop cache on all vertices in the graph.
  See [note](#methods-note) above.

* ``createFastPathCache()``

  Generate the next hop tables for every vertex in the graph.
  See [note](#methods-note) above.

* ``clearFastPathCache()``

  Clear the next hop cache on all vertices in the graph.
  See [note](#methods-note) above.

* ``resetFastPath()``

  Clear and then re-create next hop cache for the graph.
  **Note**:  This is the only cache manipulation method on the base
  ``FastPathGraph`` class that should be used by most external callers that
  are not implementing part of the cache logic.

* ``getFastPath(vertex0, vertex1)``

  Returns the next hop in the path from the first argument to the second.

  Arguments can be vertex IDs or ``Vertex`` instances.

  **Note**:  This is **not** the general-use pathfinding method, this is
  **only** for getting the next hop (the single next step) within a single
  zone.  Most callers should probably use ``findPath()`` instead.

* ``findPathInSingleZone(vertex0, vertex1)``

  Returns an array in which each element is a vertex in the path between the
  first argument and the second.

  This method only uses a single zone.  That is, it assumes all vertices are
  in a single set of next hop tables.

  Arguments can be vertex IDs or ``Vertex`` instances.

  **Note**:  This is **not** the general-use pathfinding method, most callers
  should probably use ``findPath()`` instead.

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

<a name="examples"/></a>
## Examples

<a name="generic"/></a>
### Generic Pathfinding

To use the fastPath module's pathfinding on a generic graph, use the
``FastPathGraph`` class.  Declaring graphs works the same way as in the
base ``Graph`` class.  For more information on it, see the documentation for
the [dataTypes](https://github.com/diegesisandmimesis/dataTypes) module.

Example:
```
// Declare a graph.  None of this is specific to the pathfinder code, see
// the documentation for the base Graph class for more details.
graph0: FastPathGraph
        [       'in',   'foo',  'bar',  'baz',  'out'   ]
        [
                0,      1,      0,      0,      0,
                1,      0,      1,      1,      0,
                0,      1,      0,      1,      0,
                0,      1,      1,      0,      1,
                0,      0,      0,      0,      1
        ]
;

// Return value will be a List.  On success the contents will be each
// Vertex instance in the path, starting with the "in" Vertex instance
// and ending with the "out" Vertex instance.  On failure the list
// will be empty.
local p = graph0.findPath('in', 'out');
```

<a name="room"/></a>
### Room Pathfinding

To do pathfinding through the gameworld, use the ``RoomPathfinder`` class.

#### Basic Room Pathfinding

Simplest case all you need is to declare a ``RoomPathfinder`` instance and
then call its ``findPath()`` method.  The arguments are the two Room
instances to find a path between.

The return value will always be a ``List``.  On success it will contain
the ``Room`` instances in the path, including the endpoints.  On failure
an empty list will be returned.
```
// Declare a pathfinder.
pathfinder: RoomPathfinder;

// Get the path.
local p = pathfinder.findPath(room1, room2);
```

#### Per-Actor Pathfinding

By default ``RoomPathfinder`` will use ``gameMain.initialPlayerChar`` to
test travel connectors.  The actor can be changed by setting the
``fastPathActor`` property on the ``RoomPathfinder`` instance.

If pathfinding needs to work differently for different characters, multiple
``RoomPathfinder`` instances can be declared.  Note that the overhead
grows linearly with each additional instance.

```
// Declare a pathfinder for an NPC named Alice.
alicePathfinder: RoomPathfinder
	fastPathActor = alice
;

// Declare a pathfinder for an NPC named Bob.
bobPathfinder: RoomPathfinder
	fastPathActor = bob
;
```

#### Declaring Multiple Zones

#### Updating the Pathfinder
