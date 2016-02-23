/*
 * PROJ1-1: YOUR TASK B CODE HERE
 *
 * Feel free to define additional helper functions.
 */

#include <stdlib.h>
#include <stdio.h>
#include "quadtree.h"
#include "make_qtree.h"
#include "utils.h"

#define ABS(x) (((x) < 0) ? (-(x)) : (x))

typedef struct {
    int x, y;
} Point;

Point new_point(int x, int y) {
    Point point;
    point.x = x;
    point.y = y;
    return point;
}

int homogenous(unsigned char *depth_map, int map_width, int x, int y, int section_width) {
    /* YOUR CODE HERE */
    int value = depth_map[x+y*map_width];
    for (int curr_y = y; curr_y < y+section_width; curr_y++) {
        for (int curr_x = x; curr_x < x+section_width; curr_x++) {
            //they're not equal
            if (depth_map[curr_x+curr_y*map_width] != value) {
                return 256;
            }
        }
    }
    //homogenous
    return value;
}



qNode *depth_helper(qNode *node, unsigned char *map, int map_width, int section_width, int x, int y) {
    //get the four coordinates
    Point NW = new_point(x, y);
    Point NE = new_point(x+section_width/2, y);
    Point SE = new_point(x+section_width/2, y+section_width/2);
    Point SW = new_point(x, y+section_width/2);
    //get whether they are homogenous or not
    int NW_homogenous = homogenous(map, map_width, NW.x, NW.y, section_width/2);
    int NE_homogenous = homogenous(map, map_width, NE.x, NE.y, section_width/2);
    int SE_homogenous = homogenous(map, map_width, SE.x, SE.y, section_width/2);
    int SW_homogenous = homogenous(map, map_width, SW.x, SW.y, section_width/2);
    if (((NW_homogenous == NE_homogenous) && (NW_homogenous == SE_homogenous) && (NW_homogenous == SW_homogenous)) && NW_homogenous != 256) {
        //if they are all equal, make node equal a new one
        *node = (qNode) {1, section_width, x, y, map[x+y*map_width], NULL, NULL, NULL, NULL};
        return node;
    } else {
        //if not, still make node equal a new one, but set up its children
        *node = (qNode) {0, section_width, x, y, 256, malloc(sizeof(qNode)), malloc(sizeof(qNode)), malloc(sizeof(qNode)), malloc(sizeof(qNode))};
    }
    if (node->child_NW == NULL || node->child_NE == NULL || node->child_SE == NULL || node->child_SW == NULL) {
        allocation_failed();
    }
    node->child_NW = depth_helper(node->child_NW, map, map_width, section_width/2, NW.x, NW.y);
    node->child_NE = depth_helper(node->child_NE, map, map_width, section_width/2, NE.x, NE.y);
    node->child_SE = depth_helper(node->child_SE, map, map_width, section_width/2, SE.x, SE.y);
    node->child_SW = depth_helper(node->child_SW, map, map_width, section_width/2, SW.x, SW.y);
    return node;
}

qNode *depth_to_quad(unsigned char *depth_map, int map_width) {
    if (map_width == 0) {
        return NULL;
    }
    qNode *node = malloc(sizeof(qNode));
    if (node == NULL) {
        //if allocation ever fails
        allocation_failed();
    }
    node = depth_helper(node, depth_map, map_width, map_width, 0, 0);
    return node;
}

void free_qtree(qNode *qtree_node) {
    if(qtree_node) {
        if(!qtree_node->leaf){
            free_qtree(qtree_node->child_NW);
            free_qtree(qtree_node->child_NE);
            free_qtree(qtree_node->child_SE);
            free_qtree(qtree_node->child_SW);
        }
        free(qtree_node);
    }
}
