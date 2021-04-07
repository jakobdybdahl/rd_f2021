/**
* Name: malicious
* Based on the internal empty template. 
* Author: ralle
* Tags: 
*/


model malicious

/* Insert your model definition here */
import 'particle.gaml'

species malicious parent: particle {
	rgb default_color <- #red;
	
	int bid(int expected_time) {
		if computing_slots <= 0 {
			return -1;
		}
		
		float bid <- gauss_rnd(rnd(expected_time * m_lower_bid_factor, expected_time), expected_time * m_variance_factor);
		current_bid <- bid;
		current_expection <- expected_time;
		return bid;
	}
	
	action start_computing(int bid, particle auctioneer) {
		if computing_slots <= 0 {
			return -1;
		}

		computing_slots <- computing_slots - 1;
		computing_start <- float(cycle);
		computing_end <- cycle + gauss_rnd(current_expection, current_expection * m_variance_factor); 
		computing_for <- auctioneer;
	}
	
	reflex complete_computing when: cycle >= computing_end {
		computing_slots <- computing_slots + 1;
		float result <- (computing_start+current_bid) - computing_end;

		ask computing_for {
			do rate(result, myself);
		}
		
		computing_end <- #infinity;
	}
}