/**
* Name: agent
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model agent

import "_main.gaml"
import 'submitter.gaml'
import 'worker.gaml'

species particle {
	navigation_cell my_cell <- one_of(navigation_cell);
	rgb color <- nil;
	int processing_power <- 5;
	submitter submitter <- nil;
	worker worker <- nil;
	
	list<particle> connected_particles -> particle where (each.name != self.name);
	
	init {
		location <- my_cell.location;
		
		create submitter {
			myself.submitter <- self;
			self.particle <- myself;
			self.processing_power <- myself.processing_power;
		}
		
		create worker {
			myself.worker <- self;
			self.particle <- myself;
			self.processing_power <- myself.processing_power;
		}
	}
	
	aspect base {
		draw circle(1) color: color;
		draw string(name) size: 1 color: #black;
	}
	
	action rate(float result, particle p) {
		
	}
}

