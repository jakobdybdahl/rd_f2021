/**
* Name: worker
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model worker

import 'submitter.gaml'

species worker parent: component {
	float malicious_factor <- 1.0;
	int max_queue_length <- rnd(2, 10);
	
	pair<bool, int> request_to_process(work_unit wu) {		
		if ((length(work_queue) < max_queue_length)) {		
			// calculate estimation
			int estimated_processing_time <- 0;
			loop wu_in_queue over: work_queue {
				estimated_processing_time <- estimated_processing_time + wu_in_queue.processing_units;
			}
			estimated_processing_time <- int(ceil(estimated_processing_time / processing_power) * malicious_factor);
			
			return true::estimated_processing_time;
		}
		// request is rejected
		return false::0;
	}
	
	action start_processing(work_unit wu) {
		add wu at: 0 to: work_queue;
	}
}
