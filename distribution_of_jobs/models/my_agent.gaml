/**
* Name: agent
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model agent

import "_main.gaml"

species my_agent {
	navigation_cell my_cell <- one_of(navigation_cell);
	rgb color <- nil;
	int processing_power <- 1;
	submitter submitter <- nil;
	worker worker <- nil;
	
	init {
		location <- my_cell.location;
		
		create submitter {
			myself.submitter <- self;
			self.agent <- myself;
		}
		
		create worker {
			myself.worker <- self;
			self.agent <- myself;
		}
	}
	
	aspect base {
		draw circle(1) color: color;
		draw string(name) size: 1 color: #black;
	}
	
	
}

