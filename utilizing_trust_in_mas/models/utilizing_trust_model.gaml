/**
* Name: utilizingtrustmodel
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model utilizingtrustmodel

/* Insert your model definition here */

global {
	int min_movement_radius <- 10;
	int max_movement_radius <- 25;
	int min_comm_radius <- 5;
	int max_comm_radius <- 20;
	
	init {
		create particle number: 50;
	}
}

species particle skills: [moving] {
	navigation_cell my_cell <- one_of(navigation_cell);
	int movement_radius <- rnd(min_movement_radius, max_movement_radius);
	int comm_radius <- rnd(min_comm_radius, max_comm_radius);
	geometry bounds <- circle(movement_radius, my_cell.location);
	
	list<particle> in_connection_radius -> particle at_distance comm_radius;
	// TODO could it be done faster/better using each.comm_radius somehow?
	list<particle> connected_particles -> in_connection_radius where (each.in_connection_radius contains self);
	init {
		location <- my_cell.location;
	}
	
	reflex move {
		do wander(1, 100, bounds);
	}
	
	aspect base {
		rgb pcolor <- (!empty(connected_particles)) ? #green : #red;
		draw circle(1) color: pcolor;
		draw circle(movement_radius, bounds.location) border: #black color: #transparent;
		draw circle(comm_radius) color: #transparent border: #lightblue; 
	}
}

species benign parent: particle {
	
}

species uncooperative parent: particle {
	
}

species malicious parent: particle {
	
}

grid navigation_cell width: 50 height: 50 neighbors: 4 {
	
}

experiment utilizing_trust type: gui {
	output {
		display main_display {
			grid navigation_cell lines: #black;
			species particle aspect: base;
		}
	}
}
