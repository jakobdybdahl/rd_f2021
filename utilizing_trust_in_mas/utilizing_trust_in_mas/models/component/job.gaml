/**
* Name: job
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model job

import "submitter.gaml"

species work_unit {
	int id <- 0;
	submitter requester <- nil;
	int initial_processing_units <- 0;
	int processing_units <- 0;
	bool has_been_processed <- false;
	int start_time <- 0;
	int end_time <- 0;
	pair<int, worker> bidder <- nil;
}

species job {
	list<work_unit> work_units <- [];
	int start_time <- 0;
	int end_time <- 0;
	int acc_bid_diff <- 0;
	float estimated_sequential_processing_time <- 0.0;
	int work_units_processed_by_self <- 0;
}

