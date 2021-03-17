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
	
	// Could get complicated by looking at the agents that is connected to this, and then bid a little higher, than we think they will - idk if that is possible.
	// It is probably the same agents that is connected to the auctioneer.
	
	float compute(float bid) {
		// We are not using all the power we bid with.
		// Isn't this the same/equivalent as taking longer time than promised?
		float power_used <- rnd(bid * 0.5, bid);
		float power_alloc_ratio <- power_used / bid;
		
		available_power <- available_power + bid;
		return power_alloc_ratio;
	}
}