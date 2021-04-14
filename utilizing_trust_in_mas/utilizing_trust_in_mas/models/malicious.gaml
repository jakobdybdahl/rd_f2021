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
	
	init {
		self.worker.malicious_factor <- 0.5;
	}
}