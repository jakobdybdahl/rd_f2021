/**
* Name: submitter
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model submitter

import 'work_unit.gaml'
import 'component.gaml'


species submitter parent: component {
	job active_job <- nil;
	
	reflex do_job when: flip(0.05) and active_job = nil {
		// create job
		create job {
			set start_time <- time;
			myself.active_job <- self;
		}		
		
		// create work units
		int n_of_work_units <- rnd(2, 10);
		loop i from: 0 to: n_of_work_units-1 {
			create work_unit {
				set id <- i;
				set processing_units <- rnd(1,10);
				set initial_processing_units <- self.processing_units;
				set requester <- myself;
				add self at: 0 to: myself.active_job.work_units;
			}
		}
		
//		write self.name + ': starting job consisting of ' + n_of_work_units + ' work units';
		
		// map of workers <name::{declined,worker}>
		map<string, pair<bool, worker>> workers <- (worker where (each.agent.name != self.agent.name)) as_map (each.name :: (false::each));
		list<work_unit> wus <- active_job.work_units;
		
		// distribute job to workers as long there are workers willing to accept work and there are unqueud work units
		int wu_index <- 0;
		loop while: (workers one_matches (each.key = false)) and (wu_index < length(wus)) {
			pair<int, worker> lowest_bidder <- #infinity::nil;
			loop w over: workers where (each.key = false) {
				pair<bool, int> bid <- w.value.request_to_process(wus[wu_index]);
				if (bid.key = true and lowest_bidder.key > bid.value) { 
					// request is accepted and better than previous
					lowest_bidder <- (bid.value)::w.value;
				} else if (bid.key = false) {
//					write 'declined: work unit #' + wus[wu_index].id + ' declined by ' + w.value.name;
					workers[w.value.name] <- true::w.value;
				}
			}
			if (lowest_bidder.value != nil) {
//				write self.name + ': asking ' + lowest_bidder.value.name + ' to process work unit #' + wus[wu_index].id;
				ask lowest_bidder.value {
					do start_processing(wus[wu_index]);
				}
				wu_index <- wu_index + 1;
			}
		}
		
		if (length(wus) - wu_index > 0) {
			// there are more work units to process - add them to own queue
			write self.name + ': adding ' + (length(wus) - wu_index) + ' to own queue';
			loop i from: wu_index to: length(wus)-1 {
				add wus[i] at: 0 to: work_queue;
			}
		}
		
		// calculate estimated sequential processing time (used to calculate speedup)
		loop wu over: active_job.work_units {
			active_job.estimated_sequential_processing_time <- active_job.estimated_sequential_processing_time + wu.initial_processing_units;
		}
		active_job.estimated_sequential_processing_time <- ceil(active_job.estimated_sequential_processing_time / processing_power);
	}
	
	action receive_work_unit_result(component from, int work_unit_id, int result) {
		active_job.work_units[work_unit_id].has_been_processed <- true;
		
		if (empty(active_job.work_units where (each.has_been_processed = false))) {
			// there are no work units which has not been processed			
			active_job.end_time <- time;
			
			// clear active job and work units;
			loop wu over: active_job.work_units {
				ask wu {
					 do die;
				}
			}
			active_job <- nil; // active job is not 'killed' since the result should be saved.
		}
	}
}