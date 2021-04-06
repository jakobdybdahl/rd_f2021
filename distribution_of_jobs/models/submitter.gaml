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
	int processing_power <- 1;
	
	reflex do_job when: flip(0.05) and active_job = nil {
		// create job
		create job {
			set start_time <- time;
			myself.active_job <- self;
		}		
		// write self.name + ': starting job consisting of ' + n_of_work_units + ' work units';
		
		// create work units
		int n_of_work_units <- rnd(2, 10);
		loop i from: 0 to: n_of_work_units {
			create work_unit {
				set id <- i;
				set processing_units <- rnd(1,20);
				set initial_processing_units <- self.processing_units;
				set requester <- myself;
				add self at: 0 to: myself.active_job.work_units;
			}
		}
		
		// map of workers <name::{declined,worker}>
		map<string, pair<bool, worker>> workers <- (worker where (each.agent.name != self.agent.name)) as_map (each.name :: (false::each));
		list<work_unit> wus <- active_job.work_units;
		
		int work_unit_index <- 0;
		loop while: !(workers all_match each.key = true) and length(wus) > 0 {
			loop w over: workers {
				bool confirmed <- w.value.request_to_process(wus[work_unit_index]);
				if (confirmed) {
					// remove work unit from pool
					
					work_unit_index <- work_unit_index + 1;
				} else {
					workers[w.value.name] <- true::w.value;
				}
			}
		}		
		
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
			active_job.estimated_sequential_processing_time <- active_job.estimated_sequential_processing_time + (wu.initial_processing_units / processing_power);
		}
	}
	
	action receive_work_unit_result(component from, int work_unit_id, int result) {
		// write self.name + ': received work result from ' + from.name + ' of ' + result;
		active_job.work_units[work_unit_id-1].has_been_processed <- true;
		
		if (empty(active_job.work_units where (each.has_been_processed = false))) {
			// there are no work units which has not been processed			
			active_job.end_time <- time;
			
			// clear active job and work units;
			loop wu over: active_job.work_units {
				ask wu {
					do die;
				}
			}
			active_job <- nil;
		}
	}
}