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
	
	float compute(float bid) {
		float power_used <- bid;
		float power_alloc_ratio <- power_used / bid;
		// Maybe flip and sometimes perform worse than expected?
		
		available_power <- available_power + bid;
		return power_alloc_ratio;
	}
}