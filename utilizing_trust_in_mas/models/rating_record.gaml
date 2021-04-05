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
	map<string, float> global_ratings <- [];
	float global_rating <- 0.0;
	float local_rating <- 0.0;
	map<int, float> encounters <- []; // list of pairs containing: <cycle>::<rating>
	int nEncounters <- 0;
	int latestEncounter <- 0;
}