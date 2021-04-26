/**
* Name: basecomponent
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model base_component

import "../particle.gaml"
import "job.gaml"

species base_component {
	particle particle <- nil;
	int processing_power <- 20;
	list<work_unit> work_queue <- [];
	
	reflex do_work when: length(work_queue) > 0 {
		// get the last one in queue (the oldest)
		work_unit wu <- work_queue[length(work_queue)-1];
		
		// ensure the work units i not worked on in the same cycle it is created
		if (wu.start_time < cycle) {
			do process_work_unit(wu, processing_power);
		}
	}
	
	action process_work_unit(work_unit wu, int power) {
//		write self.name + ' processing work unit #' + wu.id + ' (' + wu.processing_units + ')' + ' with ' + power + ' for ' + wu.requester.name;
		 
		// update processing time
		int processing_units_left <- wu.processing_units - power;
		wu.processing_units <- processing_units_left;
		
		// is the work unit done?
		if (processing_units_left <= 0) {
			// inform requester about result 
			ask wu.requester {
				do receive_work_unit_result(myself, wu.id);
			}
			// remove work unit from queue
			remove index: length(work_queue)-1 from: work_queue;	
			
			// if more processing power, use rest on the next work unit
			if (processing_units_left < 0 and length(work_queue) > 0) {
				do process_work_unit(work_queue[length(work_queue)-1], abs(processing_units_left));
			}	
		}
	}
}
