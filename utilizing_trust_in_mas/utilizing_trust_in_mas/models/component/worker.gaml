/**
* Name: worker
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model worker

import "base_component.gaml"

species worker parent: base_component {
	bool is_malicious <- false;
	int max_queue_length <- 20;
	
	pair<bool, int> request_to_process(work_unit wu) {		
		if (length(work_queue) < max_queue_length) {		
			// calculate estimation
			int estimated_processing_time <- wu.initial_processing_units;
			loop wu_in_queue over: work_queue {
				estimated_processing_time <- estimated_processing_time + wu_in_queue.processing_units;
			}
			estimated_processing_time <- int(ceil((estimated_processing_time / processing_power) * (is_malicious ?  rnd(0.5, 0.9) : rnd(0.9, 1.1))));
			
			return true::estimated_processing_time;
		}
		// request is rejected
		return false::0;
	}
	
	action start_processing(work_unit wu) {
		add wu at: 0 to: work_queue;
	}
}
