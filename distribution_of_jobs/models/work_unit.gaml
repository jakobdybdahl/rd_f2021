/**
* Name: workunit
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model workunit

import 'submitter.gaml'

species work_unit {
	int id <- 0;
	submitter requester <- nil;
	int initial_processing_units <- 0;
	int processing_units <- 0;
	bool has_been_processed <- false;
}

species job {
	list<work_unit> work_units <- [];
	float start_time <- 0.0;
	float end_time <- 0.0;
	float estimated_sequential_processing_time <- 0.0;
}
