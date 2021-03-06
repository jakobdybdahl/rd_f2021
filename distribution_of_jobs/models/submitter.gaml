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
	
	reflex do_job when: flip(0.05) and (submitter none_matches (each.active_job != nil)) {
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
				set start_time <- cycle;
				set processing_units <- rnd(100,150);
				set initial_processing_units <- self.processing_units;
				set requester <- myself;
				add self at: i to: myself.active_job.work_units;
			}
		}
		
		// -- calculate estimated sequential processing time (used to calculate speedup) --
		// sum up existing work units in queue
		loop wu over: work_queue {
			active_job.estimated_sequential_processing_time <- active_job.estimated_sequential_processing_time + ceil(wu.processing_units / processing_power);
		}
		// sum up work units of job		
		loop wu over: active_job.work_units {
			active_job.estimated_sequential_processing_time <- active_job.estimated_sequential_processing_time + ceil(wu.processing_units / processing_power);
		}
		// -----------
		
		write self.name + ': starting job consisting of ' + n_of_work_units + ' work units';
		
		// map of connected workers <name::{declined,worker}>
		list<worker> c_workers <- nil;
//		if empty(self.particle.benign_particles) or flip(exp(-cycle / 250)) {
//			c_workers <- self.particle.connected_particles collect each.worker;	
//		} else {
//			c_workers <- (self.particle.connected_particles where (self.particle.benign_particles contains each)) collect each.worker;				
//		}
		
		c_workers <- self.particle.connected_particles collect each.worker;
		
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
			
			// safe bidder for rating later
			wus[wu_index].bidder <- lowest_bidder;
			 
			if (lowest_bidder.value != nil) {
				// some worker came with a better bid than our own
				write self.particle.name + '/' + self.name + ': asking ' + lowest_bidder.value.particle.name + '/' + lowest_bidder.value.name + '(bid = ' + lowest_bidder.key + ') to process work unit #' + wus[wu_index].id + '(units = ' + wus[wu_index].processing_units + ')';
				ask lowest_bidder.value {
					do start_processing(wus[wu_index]);
				}
				wu_index <- wu_index + 1;
			} else {
				// if own bid is better, add to own queue
				write self.particle.name + '/' + self.name + ': adding work unit #' + wus[wu_index].id + ' (units = ' + wus[wu_index].processing_units + ') to own queue (bid = ' + own_bid + ')';
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
	}
	
	action receive_work_unit_result(base_component from, int work_unit_id) {
		active_job.work_units[work_unit_id].has_been_processed <- true;
		active_job.work_units[work_unit_id].end_time <- cycle;
		
		write self.name + ': received work unit result for #' + work_unit_id + '. Bid = ' + active_job.work_units[work_unit_id].bidder.key + ', result = ' + (active_job.work_units[work_unit_id].end_time - active_job.work_units[work_unit_id].start_time);
		
		if (empty(active_job.work_units where (each.has_been_processed = false))) {
			// job done - there are no work units which has not been processed			
			active_job.end_time <- cycle;
			
			write self.name + ': job done. Time = ' + (active_job.end_time - active_job.start_time) + '. Estimated = ' + active_job.estimated_sequential_processing_time;
			
			// calculate result of job
			loop wu over: active_job.work_units {
				if (wu.bidder.value != nil) {	
					float res <- float((wu.start_time + wu.bidder.key) - wu.end_time);
					ask self.particle {
						do rate(res, wu.bidder.value.particle);
					}
					active_job.acc_bid_diff <- active_job.acc_bid_diff + int(abs(res));
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