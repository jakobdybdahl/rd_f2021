/**
* Name: benign
* Based on the internal empty template. 
* Author: ralle
* Tags: 
*/


model benign

/* Insert your model definition here */
import 'particle.gaml'

species benign parent: particle {
	rgb default_color <- #blue; 
	
	int bid(int expected_time) {
		if computing_slots <= 0 {
			return -1;
		}
		
		float bid <- gauss_rnd(expected_time, expected_time * 0.1);
		current_bid <- bid;
		
		return bid;
	}
	
	action start_computing(int bid, particle auctioneer) {
		if computing_slots <= 0 {
			return;
		}

		computing_slots <- computing_slots - 1;
		computing_start <- float(cycle);
		computing_end <- cycle + gauss_rnd(bid, bid * 0.1); 
		computing_for <- auctioneer;
	}
	
	reflex complete_computing when: cycle >= computing_end {
		computing_slots <- computing_slots + 1;
		int result <- int((computing_start+current_bid) - computing_end); // may allow some margin?

		ask computing_for {
			do rate(result, myself);
		}
		
		computing_end <- #infinity;
	}
}