/**
* Name: submitter
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model submitter

import "base_component.gaml"
import "worker.gaml"

species submitter parent: base_component {
	job active_job <- nil;
	
	reflex do_job when: flip(0.05) and active_job = nil {
		// create job
		create job {
			set start_time <- cycle;
			myself.active_job <- self;
		}		
		
		// create work units
		int n_of_work_units <- rnd(2, 10);
		loop i from: 0 to: n_of_work_units-1 {
			create work_unit {
				set id <- i;
				set processing_units <- rnd(100,150);
				set initial_processing_units <- self.processing_units;
				set requester <- myself;
				add self at: 0 to: myself.active_job.work_units;
			}
		}
		
		write self.name + ': starting job consisting of ' + n_of_work_units + ' work units';
		
		// map of connected workers <name::{declined,worker}>
		list<worker> c_workers <- self.particle.connected_particles collect each.worker;
		map<string, pair<bool, worker>> workers <- c_workers as_map (each.name :: (false::each));
		list<work_unit> wus <- active_job.work_units;
		
		// distribute job to workers as long there are workers willing to accept work and there are unqueud work units
		int wu_index <- 0;
		loop while: (workers one_matches (each.key = false)) and (wu_index < length(wus)) {
			int own_bid <- wus[wu_index].initial_processing_units;
			loop wu_in_queue over: work_queue {
				own_bid <- own_bid + wu_in_queue.processing_units;
			}
			own_bid <- int(ceil(own_bid / processing_power));
			
			pair<int, worker> lowest_bidder <- own_bid::nil;
			loop w over: workers where (each.key = false) {
				pair<bool, int> bid <- w.value.request_to_process(wus[wu_index]);
				if (bid.key = true and lowest_bidder.key > bid.value) { 
					// request is accepted and better than previous
					lowest_bidder <- (bid.value)::w.value;
				} else if (bid.key = false) {
					write 'declined: work unit #' + wus[wu_index].id + ' declined by ' + w.value.name;
					workers[w.value.name] <- true::w.value;
				}
			}
			if (lowest_bidder.value != nil) {
				// some worker came with a better bid than our own
				write self.particle.name + '/' + self.name + ': asking ' + lowest_bidder.value.particle.name + '/' + lowest_bidder.value.name + '(bid = ' + lowest_bidder.key + ', p = ' + lowest_bidder.value.processing_power + ') to process work unit #' + wus[wu_index].id + '(units = ' + wus[wu_index].processing_units + ')';
				wus[wu_index].bidder <- lowest_bidder; // safe bidder for rating later
				ask lowest_bidder.value {
					do start_processing(wus[wu_index]);
				}
				wu_index <- wu_index + 1;
			} else {
				// if own bid is better, add to own queue
				write self.particle.name + '/' + self.name + ': adding work unit #' + wus[wu_index].id + '(units = ' + wus[wu_index].processing_units + ') to own queue (bid = ' + own_bid + ')';
				add wus[wu_index] at: 0 to: work_queue;
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
		loop wu_in_queue over: work_queue {
			active_job.estimated_sequential_processing_time <- active_job.estimated_sequential_processing_time + wu_in_queue.processing_units;
		}		
		loop wu over: active_job.work_units {
			active_job.estimated_sequential_processing_time <- active_job.estimated_sequential_processing_time + wu.initial_processing_units;
		}
		active_job.estimated_sequential_processing_time <- ceil(active_job.estimated_sequential_processing_time / processing_power);
	}
	
	action receive_work_unit_result(base_component from, int work_unit_id) {
		active_job.work_units[work_unit_id].has_been_processed <- true;
		active_job.work_units[work_unit_id].end_time <- cycle;
		
		if (empty(active_job.work_units where (each.has_been_processed = false))) {
			// job done - there are no work units which has not been processed			
			active_job.end_time <- cycle;
			
			// calculate result of job
			loop wu over: active_job.work_units {
				if (wu.bidder.value != nil) {	
					float res <- float((wu.start_time + wu.bidder.key) - wu.end_time);
					ask self.particle {
						do rate(res, wu.bidder.value.particle);
					}
				}
			}
			
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