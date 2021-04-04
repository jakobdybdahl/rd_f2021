/**
* Name: submitter
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model submitter

import 'my_agent.gaml'
import 'work_unit.gaml'
import '_main.gaml'

species component {
	int processing_power <- 1;
	my_agent agent <- nil;
}


species submitter parent: component {
	job active_job <- nil;
	int processing_power <- 1;
	list<work_unit> work_queue <- [];
	
	reflex do_work when: length(work_queue) > 0 {
		// get the last one in queue (the oldest)
		work_unit wu <- work_queue[length(work_queue)-1];
		write self.name + ': doing work of id ' + wu.id;
		
		// update processing time
		wu.processing_units <- wu.processing_units - self.processing_power;
		
		if (wu.processing_units <= 0) {
			// inform requester about result
			write self.name + ': finish processing work unit #' + wu.id; 
			ask wu.requester {
				// TODO how to calculate result?
				int result <- 1;
				do receive_work_unit_result(myself, wu.id, result);
			}
			
			// remove work unit from queue
			remove index: length(work_queue)-1 from: work_queue;
			write self.name + ': work queue length = ' + length(work_queue);			
		}
	} 
	
	reflex do_job when: flip(0.05) and active_job = nil {
		create job {
			set start_time <- cycle;
			myself.active_job <- self;
		}		
		int n_of_work_units <- rnd(2, 10);
		write self.name + ': starting job consisting of ' + n_of_work_units + ' work units';
		
		list<worker> workers <- worker where (each.agent.name != self.agent.name);
		
		loop i from: 0 to: min(length(workers)-1, n_of_work_units-1) {
			create work_unit {
				set id <- i + 1;
				set processing_units <- rnd(1,20);
				set initial_processing_units <- self.processing_units;
				set requester <- myself;
				add self at: 0 to: myself.active_job.work_units;
				// TODO use confirmed to something
				bool confirmed <- workers[i].request_to_process(self);	
			}
		}
		
		if (n_of_work_units-1 > length(workers)-1) {
			loop i from: length(workers) to: n_of_work_units-1 {
				create work_unit {
					set id <- i + 1;
					set processing_units <- rnd(1,20);
					set initial_processing_units <- self.processing_units;
					set requester <- myself;
					add self at: 0 to: myself.active_job.work_units;
					add self at: 0 to: myself.work_queue;
				}
			}
		}
		
		loop wu over: active_job.work_units {
			active_job.estimated_sequential_processing_time <- int(active_job.estimated_sequential_processing_time + (wu.initial_processing_units / processing_power));
		}
	}
	
	action receive_work_unit_result(component from, int work_unit_id, int result) {
		write self.name + ': received work result from ' + from.name + ' of ' + result;
		
		active_job.work_units[work_unit_id-1].has_been_processed <- true;
		
		if (empty(active_job.work_units where (each.has_been_processed = false))) {
			// there are no work units which has not been processed
			int time_elapsed <- cycle - active_job.start_time;
			float speedup <- active_job.estimated_sequential_processing_time / time_elapsed;
			write self.name + ': job done! Time elapsed = ' + time_elapsed + '. Speedup = ' + speedup ;
			
			// clear active job and work units;
			loop wu over: active_job.work_units {
				ask wu {
					do die;
				}
			}
			ask active_job {
				do die;
			}
			active_job <- nil;
		}
	}
}

species worker parent: component {
	list<work_unit> queue <- [];
	
	bool request_to_process(work_unit wu) {
		// TODO implement logic to decide if the work unit will be accepted
		// save work unit in queue
		add wu at: 0 to: queue;
		write self.name + ': received work unit with id ' + wu.id + '. Queue length ' + length(queue);
		return true;
	}
	
	reflex work when: length(queue) > 0 {
		// get the last one in queue (the oldest)
		work_unit wu <- queue[length(queue)-1];
		write self.name + ': doing work of id ' + wu.id + ' for ' + wu.requester.name;
		
		// update processing time
		wu.processing_units <- wu.processing_units - self.processing_power;
		
		if (wu.processing_units <= 0) {
			// inform requester about result
			write self.name + ': finish processing work unit #' + wu.id; 
			ask wu.requester {
				// TODO how to calculate result?
				int result <- 1;
				do receive_work_unit_result(myself, wu.id, result);
			}
			// remove work unit from queue
			remove index: length(queue)-1 from: queue;		
		}
	}
}