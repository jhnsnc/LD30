Enemy Patterns Info
===================

Threat progression
------------------

| level | start threat | end threat |
|-------|--------------|------------|
| 1     | 10           | 25         |
| 2     | 15           | 30         |
| 3     | 20           | 35         |
| 4     | 25           | 40         |
| 5     | 30           | 45         |
| 6     | 35           | 50         |
| 7     | 40           | 55         |

Useful mathematical transformations
-----------------------------------

# Linear #
| x   | 100 * (-1/(x+1)) + 100 |
|-----|------------------------|
| 10  | 90.91                  |
| 15  | 93.75                  |
| 20  | 95.24                  |
| 25  | 96.15                  |
| 30  | 96.77                  |
| 35  | 97.22                  |
| 40  | 97.56                  |
| 45  | 97.83                  |
| 50  | 98.04                  |
| 55  | 98.21                  |
| 60  | 98.36                  |
| 65  | 98.48                  |
| 70  | 98.59                  |
| 75  | 98.68                  |
| 80  | 98.77                  |
| 85  | 98.84                  |
| 90  | 98.90                  |
| 95  | 98.96                  |
| 100 | 99.01                  |


Pattern types
-------------
# Simple #
Enemies spawn at random locations fully independent of one another.
Can appear on any level.
At lower threat these spawns are one at a time. High threat has a chance to spawn 2 or more.
This pattern also has a high chance of reducing the spawn cooldown by a percentage that increases with theat.

# Stream #
Enemies spawn in a line one behind the other with the same orientation.
Can appear in level 1 (10+ threat). Peaks around 25 threat.

# Arc #
Similar to stream except enemies take a curved path towards their destination. 
This pattern becomes common around level 3.
This pattern increases the spawn cooldown by a small amount.

# Cluster #
Multiple enemies appear near one another, evenly spaced along an arc. 
This pattern becomes common around level 5.
This pattern increases the spawn cooldown by a moderate amount.

# DoubleSpawn #
This is not necessarily a pattern itself. Instead of creating one spawn, the roll is made twice. It has a relatively low chance of occurring--even at higher threat.
DoubleSpawn cannot produce another DoubleSpawn pattern.
Can appear near the end of level 7.
This pattern adjusts the spawn cooldown to the longer of the cooldown adjustments made by the 2 patterns produced.

Pattern probability
-------------------
Patterns should level out at around 50-weighted chance of occuring. At their most common, new patterns should have around 100-weighted chance of occuring.

