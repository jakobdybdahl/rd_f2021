/**
* Name: ratingrecord
* Based on the internal empty template. 
* Author: ralle
* Tags: 
*/


model ratingrecord

/* Insert your model definition here */

import 'particle.gaml'

species rating_record {
	particle p <- nil; 
	float global_rating <- 0.0;
	float local_rating <- 0.0;
	int encounters <- 0;
	date latestEncounter <- nil;
}