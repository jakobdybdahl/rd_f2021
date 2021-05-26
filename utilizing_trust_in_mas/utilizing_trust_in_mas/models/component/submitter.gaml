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
	
//	 reflex do_job when: flip(0.05) /*and (submitter none_matches (each.active_job != nil))*/ {
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
				set start_time <- cycle;
				set processing_units <- rnd(100,150);
				
				set initial_processing_units <- self.processing_units;
				set requester <- myself;
				add self at: i to: myself.active_job.work_units;
			}
		}
		
		// -- calculate estimated sequential processing time (used to calculate speedup) --
		// sum up existing work units in queue and work units
		active_job.estimated_sequential_processing_time <- 
			float(sum(work_queue collect each.processing_units))
			+ float(sum(active_job.work_units collect each.processing_units));

		active_job.estimated_sequential_processing_time <- ceil(active_job.estimated_sequential_processing_time / processing_power);
		// -----------
		
		 // write self.name + ': starting job consisting of ' + n_of_work_units + ' work units';
		
		
		list<worker> c_workers <- nil;
		if empty(self.particle.benign_particles) or flip(exp(-cycle / 250)) {
			// collect all unknowns
			c_workers <- self.particle.connected_particles where !(self.particle.rating_db contains_key each.name) collect each.worker;
			
			// collect all connected unclassified particles
			c_workers <- c_workers + (self.particle.connected_particles where (self.particle.unclassified_particles contains each)) collect each.worker;
			
			// collect all connected known as benign (if the flip() was true then there might be some benigns to use as well)
			c_workers <- c_workers + (self.particle.connected_particles where (self.particle.benign_particles contains each)) collect each.worker;
			
			if(length(c_workers) = 0) {
				// if we are not in radius with any unknowns nor benigns then just use all connected
				c_workers <- self.particle.connected_particles collect each.worker;	
			}	
		} else {
			c_workers <- (self.particle.connected_particles where !(self.particle.malicious_particles contains each)) collect each.worker;				
		}
				
		// map of connected workers <name::{declined,worker}>
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
					// write 'declined: work unit #' + wus[wu_index].id + ' declined by ' + w.value.name;
					workers[w.value.name] <- true::w.value;
				}
			}
			
			// safe bidder for rating later
			wus[wu_index].bidder <- lowest_bidder;
			 
			if (lowest_bidder.value != nil) {
				// some worker came with a better bid than our own
				// write self.particle.name + '/' + self.name + ': asking ' + lowest_bidder.value.particle.name + '/' + lowest_bidder.value.name + '(bid = ' + lowest_bidder.key + ') to process work unit #' + wus[wu_index].id + '(units = ' + wus[wu_index].processing_units + ')';
				ask lowest_bidder.value {
					do start_processing(wus[wu_index]);
				}
				wu_index <- wu_index + 1;
			} else {
				// if own bid is better, add to own queue
				// write self.particle.name + '/' + self.name + ': adding work unit #' + wus[wu_index].id + ' (units = ' + wus[wu_index].processing_units + ') to own queue (bid = ' + own_bid + ')';
				add wus[wu_index] at: 0 to: work_queue;
				wu_index <- wu_index + 1;
			}
		}
		
		if (length(wus) - wu_index > 0) {
			// there are more work units to process - add them to own queue
			// write self.name + ': adding ' + (length(wus) - wu_index) + ' to own queue';
			loop i from: wu_index to: length(wus)-1 {
				add wus[i] at: 0 to: work_queue;
			}
		}
		
		active_job.work_units_processed_by_self <- active_job.work_units count (each.bidder.value = nil);
		active_job.number_of_available_workers <- length(c_workers) + 1; // connected workers + our self
		
	}
	
	action receive_work_unit_result(base_component from, int work_unit_id) {
		active_job.work_units[work_unit_id].has_been_processed <- true;
		active_job.work_units[work_unit_id].end_time <- cycle;
		
		// write self.name + ': received work unit result for #' + work_unit_id + '. Bid = ' + active_job.work_units[work_unit_id].bidder.key + ', result = ' + (active_job.work_units[work_unit_id].end_time - active_job.work_units[work_unit_id].start_time);
		
		if (empty(active_job.work_units where (each.has_been_processed = false))) {
			// job done - there are no work units which has not been processed			
			active_job.end_time <- cycle;
			
			// write self.name + ': job done. Time = ' + (active_job.end_time - active_job.start_time) + '. Estimated = ' + active_job.estimated_sequential_processing_time;
			
			// calculate result of job
			loop wu over: active_job.work_units {
				if (wu.bidder.value != nil) {
					// work unit has been processed by other worker than our self, rate!	
					float res <- float((wu.start_time + wu.bidder.key) - wu.end_time);
					ask self.particle {
						do rate(res, wu.bidder.value.particle);
					}
					active_job.acc_bid_diff <- active_job.acc_bid_diff + int(abs(res));
				}
			}
			
			// set expected speedup
			if (active_job.work_units one_matches (each.bidder.value != nil)) {
				active_job.expected_speedup <- active_job.estimated_sequential_processing_time / max(active_job.work_units collect each.bidder.key);	
			} else {
				// if only done by our self expected speedup is 1.0
				active_job.expected_speedup <- 1.0;
			}
			// set actual speedup
			// acc_bid_diff is to offset a malicious bid by the amount it was slower than expected.
			active_job.actual_speedup <- active_job.estimated_sequential_processing_time / ((active_job.end_time - active_job.start_time) + active_job.acc_bid_diff);
			
			// clear active job and work units;
			loop wu over: active_job.work_units {
				ask wu {
//					 do die;
				}
			}
			active_job <- nil; // active job is not 'killed' since the result should be saved.
		}
	}
}