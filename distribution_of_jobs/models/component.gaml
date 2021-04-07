/**
* Name: component
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/



model component

import 'my_agent.gaml'

species component {
	int processing_power <- rnd(1, 10);
	my_agent agent <- nil;
	list<work_unit> work_queue <- [];
	
	reflex do_work when: length(work_queue) > 0 {
		// get the last one in queue (the oldest)
		work_unit wu <- work_queue[length(work_queue)-1];
		
//		write self.name + ': doing work of id ' + wu.id + ' for ' + wu.requester.name;
				
		// update processing time
		wu.processing_units <- wu.processing_units - self.processing_power;
		
		if (wu.processing_units <= 0) {
			// inform requester about result
			// write self.name + ': finish processing work unit #' + wu.id; 
			ask wu.requester {
				// TODO how to calculate result?
				int result <- 1;
				do receive_work_unit_result(myself, wu.id, result);
			}
			// remove work unit from queue
			remove index: length(work_queue)-1 from: work_queue;		
		}
	}
}
