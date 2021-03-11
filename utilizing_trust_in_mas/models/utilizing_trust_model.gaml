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
		create benign number: 30;
		create uncooperative number: 10;
	}
}

species particle skills: [moving] {
	navigation_cell my_cell <- one_of(navigation_cell);
	int movement_radius <- rnd(min_movement_radius, max_movement_radius);
	int comm_radius <- rnd(min_comm_radius, max_comm_radius);
	geometry bounds <- circle(movement_radius, my_cell.location);
	
	rgb default_color <- #blue;
	rgb connected_color <- #green;
	
	list in_connection_radius -> (agents_at_distance(comm_radius)) of_generic_species particle;
	// TODO could it be done faster/better using each.comm_radius somehow?
	list connected_particles -> in_connection_radius where (each.in_connection_radius contains self);
	// TODO Use matrix as rating DB? With particle, rating and timestamp
	list trusted_particles <- [];
	
	init {
		location <- my_cell.location;
	}
	
	reflex move {
		do wander(1.0, 100.0, bounds);
	}
	
	aspect base {
		rgb pcolor <- (!empty(connected_particles)) ? connected_color : default_color;
		draw circle(1) color: pcolor;
		draw circle(movement_radius, bounds.location) border: #black color: #transparent;
		draw circle(comm_radius) color: #transparent border: #lightblue; 
	}
	 
	float compute {
		return 0;
	}
}

species benign parent: particle {
	rgb default_color <- #blue; 
	
	float compute {
		return 1;
	}
}

species uncooperative parent: particle {
	rgb default_color <- #red;
	rgb connected_color <- #lightgreen;
	float compute {
		return -1;
	}
}

species malicious parent: particle {

}

grid navigation_cell width: 50 height: 50 neighbors: 4 {
	
}

experiment utilizing_trust type: gui {
	output {
		display main_display {
			grid navigation_cell lines: #black;
			species benign aspect: base;
			species uncooperative aspect: base;
			species particle aspect: base;
		}
	}
}
