# Common stuff / Constants

Constants =
    EntityOrient :
        NW: 0
        NE: 1
        SE: 2
        SW: 3

    LaserDirection:
        N: 0
        E: 1
        S: 2
        W: 3

    EntityType :
        MIRROR: 1
        PRISM: 2
        BLOCK: 3
        FILTER: 4
        END: 5
        START: 6
        
    RevEntityType : ['GridEntity', 'Mirror', 'Prism', 'Block', 'Filter', 'Endpoint', 'Startpoint']

exports ?= {}
exports.Constants = Constants
