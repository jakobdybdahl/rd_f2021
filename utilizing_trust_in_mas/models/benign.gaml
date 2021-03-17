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
	
	float compute {
		return 1;
	}
}