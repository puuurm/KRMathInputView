//
//  ByteNode.h
//  TestScript
//
//  Created by Joshua Park on 07/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

#ifndef ByteNode_h
#define ByteNode_h

#include <stdio.h>

typedef struct _ByteArrayIndexes {
    int*   bytes;
    size_t byteCount;
} ByteArrayIndexes;

typedef struct _ByteCandidates {
    char*  bytes;
    size_t byteCount;
} ByteCandidates;

typedef struct _ByteNode {
    ByteArrayIndexes   indexes;
    ByteCandidates candidates;
} ByteNode;

#endif /* MyScriptNode_h */
