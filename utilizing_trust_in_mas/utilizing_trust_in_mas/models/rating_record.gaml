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
	map<string, float> neighbourhood_ratings <- [];
	float neighbourhood_rating_mean <- 0.0;
	float local_rating_mean <- 0.0;
	map<int, float> encounters <- []; // list of pairs containing: <cycle>::<rating>
	int nEncounters <- 0;
	int latestEncounter <- 0;
}