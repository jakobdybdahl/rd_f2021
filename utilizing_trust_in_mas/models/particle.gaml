/**
* Name: particle
* Based on the internal empty template. 
* Author: ralle
* Tags: 
*/


model particle

/* Insert your model definition here */

import '_main.gaml'
import 'rating_record.gaml'

species particle skills: [moving] {
	navigation_cell my_cell <- one_of(navigation_cell);
	int movement_radius <- rnd(min_movement_radius, max_movement_radius);
	int comm_radius <- rnd(min_comm_radius, max_comm_radius);
	geometry bounds <- circle(movement_radius, my_cell.location);
	float broadcast_time <- 10.0;

	float available_power <- 100.0;
	
	rgb default_color <- #blue;
	rgb connected_color <- #green;
	
	list in_connection_radius -> (agents_at_distance(comm_radius)) of_generic_species particle;
	list connected_particles -> in_connection_radius where (each.in_connection_radius contains self);
	list<rating_record> rating_db <- [];
	
	init {
		location <- my_cell.location;
	}
	
	reflex move {
		do wander(1.0, 100.0, bounds);
	}
	
	reflex auction when: flip(0.2) {		
		map<particle, float> bids <- nil;
		
		if(!empty(connected_particles)) {
			bids <- connected_particles as_map (each::0.0);
			loop connected over: connected_particles {
				put connected.bid() at: connected in: bids;
			}
		}
		
		float winning_bid <- max(bids);
		particle winner <- bids index_of winning_bid;
		float res <- winner.compute(winning_bid);
		do rate(res, winner);
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
	 
	float compute(float bid) {
		write 'called base compute';
		return 0;
	}
	
	float bid {
		float bid <- rnd(0, available_power);
		
		// can we have multiple connections at once?
		if available_power - bid < 0 {
			return #infinity;
		}
		
		available_power <- available_power - bid;
		
		return bid;
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