/*
 * PROJ1-1: YOUR TASK A CODE HERE
 *
 * Feel free to define additional helper functions.
 */

#include "calc_depth.h"
#include "utils.h"
#include <math.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

/* Implements the normalized displacement function */
unsigned char normalized_displacement(int dx, int dy,
        int maximum_displacement) {

    double squared_displacement = dx * dx + dy * dy;
    double normalized_displacement = round(255 * sqrt(squared_displacement) / sqrt(2 * maximum_displacement * maximum_displacement));
    return (unsigned char) normalized_displacement;

}

typedef struct {
	int x, y;
} Point;

Point new_point(int x, int y) {
	Point point;
	point.x = x;
	point.y = y;
	return point;
}

typedef struct {
	char pixel;
	int total;
	int first;
	Point coords;
} Euc_sum;

Euc_sum new_Euc_sum(char pixel, int total, int first) {
	Euc_sum eu_sum;
	eu_sum.pixel = pixel;
	eu_sum.total = total;
	eu_sum.first = 0;
	return eu_sum;
}

/*
This function generates the search_space (the restrictions)
for variable "bounds"
*/
void generate_search_space(Point* bounds,int x, int y, 
						int feature_width, int feature_height, 
						int maximum_displacement, int image_width,
						int image_height) {
	int left_bound = x - feature_width - maximum_displacement;
	int upper_bound = y + feature_height + maximum_displacement;
	int right_bound = x + feature_width + maximum_displacement;
	int lower_bound = y - feature_height - maximum_displacement;
	while (*(&bounds[0].y) > 0 && *(&bounds[0].y) > lower_bound) {
		*(&bounds[0].y) -= 1;
	}
	while(*(&bounds[0].x) > 0 && *(&bounds[0].x) > left_bound) {
		*(&bounds[0].x) -= 1;
	}
	while (*(&bounds[1].y) < image_height-1 && *(&bounds[1].y) < upper_bound) {
		*(&bounds[1].y) += 1;
	}
	while (*(&bounds[1].x) < image_width-1 && *(&bounds[1].x) < right_bound) {
		*(&bounds[1].x) +=1;
	}
}

/*
this method is for getting the points in *left that must be
repeatedly iterated over for the euclidian sum
(currently buggy)
*/

void get_pixels_for_left(unsigned char* arr[], unsigned char *left, int size, int image_width, int x, int y, int x_bound, int y_bound) {
	int count = 0;
	for (; y <= y_bound && count < size; y++) {
		for (; x <= x_bound; x++, count++) {
			*(&arr[count]) = &left[x+y*image_width];
		}
	}
}

/*
this method is used to get the pixel with the smallest euclidian sum
*/
Point get_euclidian_sum(int x, int y, Point top_left, 
						Point bottom_right, unsigned char left_pixels[], 
						unsigned char *right_pointer, int feature_width, 
						int feature_height, int image_width, int image_height, int maximum_displacement) {
	Point coords = new_point(x, y);
	unsigned abs_min_sum = ~(0);
	for (int curr_y = (top_left.y+feature_height); curr_y <= bottom_right.y-feature_height; curr_y++) {
		for (int curr_x = (top_left.x+feature_width); curr_x <= bottom_right.x-feature_width; curr_x++) {
			unsigned curr_sum = 0;
			int count = 0;
			for (int temp_y = curr_y-feature_height; temp_y <= curr_y+feature_height; temp_y++) {
				for (int temp_x = curr_x-feature_width; temp_x <= curr_x+feature_width; temp_x++, count++) {
					curr_sum += (left_pixels[count] - right_pointer[temp_x+temp_y*image_width])
										*
								(left_pixels[count] - right_pointer[temp_x+temp_y*image_width]);
				}
			}
			if (curr_sum < abs_min_sum) {
				abs_min_sum = curr_sum;
				coords.x = curr_x;
				coords.y = curr_y;
			}  else if (curr_sum == abs_min_sum) {
					//break the tie between the two sums
					int this_x_displacement = curr_x - x;
					int this_y_displacement = curr_y - y;
					int old_x_displacement = coords.x - x;
					int old_y_displacement = coords.y - y;
					unsigned char new_nom_dis = normalized_displacement(this_x_displacement, this_y_displacement, maximum_displacement);
					unsigned char old_nom_dis = normalized_displacement(old_x_displacement, old_y_displacement, maximum_displacement);
					if (new_nom_dis < old_nom_dis) {
						abs_min_sum = curr_sum;
						coords.x = curr_x;
						coords.y = curr_y;
					}
			}
		}
	}
	return coords;
}

void calc_depth(unsigned char *depth_map, unsigned char *left,
        unsigned char *right, int image_width, int image_height,
        int feature_width, int feature_height, int maximum_displacement) {
	unsigned total_count = 0;
	for (int y = 0; y < image_height && total_count < (image_height*image_width); y++) {
		for (int x = 0; x < image_width; x++, total_count++) { //loops each char (pixel)
			if (		maximum_displacement != 0
									&&
				x >= feature_width && y >= feature_height
									&&
				x <= (image_width-feature_width-1) && y <= (image_height-feature_height-1)) {
				Point bounds[2]; //put the bounds of the search space into bounds
				bounds[0] = new_point(x, y);
				bounds[1] = new_point(x, y);
				generate_search_space(&bounds[0], x, y, feature_width, feature_height, maximum_displacement, image_width, image_height);
				int feature_size = (feature_width*2+1) * (feature_height*2+1);
				unsigned char pixels[feature_size];
				/*
				This part is for the pixels array, the one to be repeatedly iterated over
				*/
				int count = 0;
				for (int temp_y = y-feature_height; temp_y <= (y+feature_height); temp_y++) {
					for (int temp_x = x-feature_width; temp_x <= (x+feature_width); temp_x++, count++) {
						pixels[count] = left[temp_x+temp_y*image_width];
					}
				}
				/*
				This part is for the pixels array; 
				the commented out function call below is bugged
				*/
				// get_pixels_for_left(&pixels, &left[0], feature_size, image_width, (x-feature_width), (y-feature_height), (x+feature_width), (y+feature_height));
				Point pixel_coords = get_euclidian_sum(x, y, bounds[0], bounds[1], pixels, right, feature_width, feature_height, image_width, image_height, maximum_displacement);
				int x_displacement = pixel_coords.x - x;
				int y_displacement = pixel_coords.y - y;
				unsigned char displacement = normalized_displacement(x_displacement, y_displacement, maximum_displacement);
				*(depth_map+total_count) = displacement;
			} else {
				*(depth_map+total_count) = 0;
			}
		}
	}
}

