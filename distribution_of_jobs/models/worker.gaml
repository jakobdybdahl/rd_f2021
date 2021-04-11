/**
* Name: worker
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model worker

import 'submitter.gaml'

species worker parent: component {
	int max_queue_length <- rnd(2, 10);
	
	bool request_to_process(work_unit wu) {
		if ((length(work_queue) < max_queue_length) and flip(0.8)) {
			// save work unit in queue
			add wu at: 0 to: work_queue;
			return true;			
		}
		// request is rejected
//		write self.name + ' rejected work unit';
		return false;
	}
}
