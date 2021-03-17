/**
* Name: uncooperative
* Based on the internal empty template. 
* Author: ralle
* Tags: 
*/


model uncooperative

/* Insert your model definition here */
import 'particle.gaml'

species uncooperative parent: particle {
	rgb default_color <- #red;
	rgb connected_color <- #lightgreen;
	
	float compute {
		return -1;
	}
}