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

species my_agent {
	navigation_cell my_cell <- one_of(navigation_cell);
	rgb color <- nil;
//	int processing_power <- rnd(1,10);
	int processing_power <- 5;
	submitter submitter <- nil;
	worker worker <- nil;
	
	init {
		location <- my_cell.location;
		
		create submitter {
			myself.submitter <- self;
			self.agent <- myself;
			self.processing_power <- myself.processing_power;
		}
		
		create worker {
			myself.worker <- self;
			self.agent <- myself;
			self.processing_power <- myself.processing_power;
		}
	}
	
	aspect base {
		draw circle(1) color: color;
		draw string(name) size: 1 color: #black;
	}
	
	
}

