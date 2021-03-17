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

species rating_record {
	particle p <- nil; 
	float global_rating <- 0.0;
	float local_rating <- 0.0;
	int encounters <- 0;
	date latestEncounter <- nil;
}

species particle skills: [moving] {
	navigation_cell my_cell <- one_of(navigation_cell);
	int movement_radius <- rnd(min_movement_radius, max_movement_radius);
	int comm_radius <- rnd(min_comm_radius, max_comm_radius);
	geometry bounds <- circle(movement_radius, my_cell.location);
	float broadcast_time <- 10.0;
	
	rgb default_color <- #blue;
	rgb connected_color <- #green;
	
	list in_connection_radius -> (agents_at_distance(comm_radius)) of_generic_species particle;
	// TODO could it be done faster/better using each.comm_radius somehow?
	list connected_particles -> in_connection_radius where (each.in_connection_radius contains self);
	list<rating_record> rating_db <- [];

	
	init {
		location <- my_cell.location;
	}
	
	reflex move {
		do wander(1.0, 100.0, bounds);
	}
	
	reflex heavy_task when: flip(0.2) {
		if(!empty(connected_particles)) {
			loop connected over: connected_particles {
				float result <- connected.compute();
				do rate(result, connected);
			}
		}
	}
	
	// How do we broadcast?? 
	reflex broadcast when: every(broadcast_time #mn) {
		loop connected over: connected_particles {
			ask connected {
				do receive(rating_db);
			}
		}
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
	
	action rate(float res, particle connected) {
		create rating_record number: 1 returns: record_list;
		rating_record record <- record_list at 0;
		
		if(!empty(rating_db where (each.p = connected))) {
			record <- rating_db first_with (each.p = connected);
		} else {
			record.p <- connected;
		}
		
		rating_db <- rating_db - record;
		
		record.encounters <- record.encounters + 1;
		record.latestEncounter <- date("2019-09-01-00-00-00");
		record.local_rating <- record.local_rating + res;
		
		rating_db <- rating_db + record;
	}
	
	action receive(list<rating_record> db) {
		
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

species malicious parent: particle { }

grid navigation_cell width: 50 height: 50 neighbors: 4 { }

experiment utilizing_trust type: gui {
	output {
		display main_display {
			grid navigation_cell lines: #black;
			species benign aspect: base;
			species uncooperative aspect: base;
		}
	}
}
