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
	float broadcast_time <- 1.0;
	
	// Available computational power - could vary.
	float available_power <- 100.0;
	
	rgb default_color <- #blue;
	rgb connected_color <- #green;
	
	list in_connection_radius -> (agents_at_distance(comm_radius)) of_generic_species particle;
	list connected_particles -> in_connection_radius where (each.in_connection_radius contains self);
	// list<rating_record> rating_db <- [];
	map<string, rating_record> rating_db <- [];
	
	init {
		location <- my_cell.location;
	}
	
	reflex move {
		do wander(1.0, 100.0, bounds);
	}
	
	reflex auction when: flip(1) {		
		particle current_winner <- nil;
		float highest_bid <- -1.0;
		
		if(!empty(connected_particles)) {
			loop connected over: connected_particles {
				float bid <- connected.bid();
				if bid > highest_bid {
					if current_winner != nil {
						current_winner.available_power <- current_winner.available_power + bid;
					}
					
					current_winner <- connected;
					highest_bid <- bid;
				} else {
					// lost bid, so restore power:
					connected.available_power <- connected.available_power + bid;
				}
			}
			
			if highest_bid != 0 {
				float res <- current_winner.compute(highest_bid);
				do rate(res, current_winner);
			}
		}
	}
	
	// How do we broadcast?? 
	reflex broadcast {
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
		return -1;
	}
	
	float bid {
		// Instead of bidding with time, we are bidding with resource allocation
		float bid <- rnd(0, available_power);
		
		// can we have multiple connections at once?
		if available_power - bid < 0 {
			return 0;
		}
		
		available_power <- available_power - bid;
		
		return bid;
	}

	action rate(float res, particle connected) {
		create rating_record number: 1 returns: record_list;
		rating_record record <- record_list at 0;

		if rating_db contains_key connected.name {
			record <- rating_db[connected.name];
		} else {
			record.p <- connected;
		}
		
		record.encounters <- record.encounters + 1;
		record.latestEncounter <- date("2019-09-01-00-00-00");
		record.local_rating <- record.local_rating + res;
		
		put record at: record.p.name in: rating_db;
	}
	
	action receive(map<string, rating_record> db) {
		loop receiving_record over: db.values {
			create rating_record number: 1 returns: record_list;
			rating_record record <- record_list at 0;
			
			if (rating_db contains_key receiving_record.p.name) {
				record <- rating_db[receiving_record.p.name];
			} else {
				record.p <- receiving_record.p;
			}
			
			if record.global_rating = 0 {
				record.global_rating <- receiving_record.local_rating; 	
			} else {
				record.global_rating <- (record.global_rating + receiving_record.local_rating) / 2; 	
			}
			
			put record at: record.p.name in: rating_db;
		}
	}
}