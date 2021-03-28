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
	
	int computing_slots <- 1;
	float computing_end <- #infinity;
	float computing_start <- 0.0;
	float current_bid <- 0.0;
	particle computing_for <- nil;
	
	rgb default_color <- #blue;
	rgb connected_color <- #green;
	
	list in_connection_radius -> (agents_at_distance(comm_radius)) of_generic_species particle;
	list connected_particles -> in_connection_radius where (each.in_connection_radius contains self);

	map<string, rating_record> rating_db <- [];
	
	init {
		location <- my_cell.location;
	}
	
	reflex move {
		do wander(1.0, 100.0, bounds);
	}
	
	reflex auction when: flip(0.2) {		
		particle current_winner <- nil;
		int highest_bid <- -1;
		
		if(!empty(connected_particles)) {
			loop connected over: connected_particles {
				int bid <- connected.bid(rnd(5,20));
				if bid > highest_bid {
					current_winner <- connected;
					highest_bid <- bid;
				}
			}
			
			if highest_bid != 0 and current_winner != nil {
				// TODO should we store any encounter here, or first when we rate?
				// rating_db[current_winner.name].latestEncounter <- cycle;
				ask current_winner {
					do start_computing(highest_bid, myself);
				}
			}
		}
	}
	
	// How do we broadcast?? 
	reflex broadcast {
		loop connected over: connected_particles {
			ask connected {
				do receive(myself.rating_db, myself);
			}
		}
	}
	
	reflex decrease when: every(20#cycles) {
		loop record over: rating_db.values {
			loop encounter over: record.encounters {
				if (cycle - encounter.key > 100) {
					encounter <- pair<int, float>({encounter.key, encounter.value * 0.95});
				}
			}
		}
	}
	
	aspect base {
		rgb pcolor <- (!empty(connected_particles)) ? connected_color : default_color;
		draw circle(1) color: pcolor;
		draw circle(movement_radius, bounds.location) border: #black color: #transparent;
		draw circle(comm_radius) color: #transparent border: #lightblue; 
	}
	 
	action start_computing(int bid, particle auctioneer) {
		return;
	}
	
	int bid(int expected_time) {
		return -1;
	}

	action rate(int res, particle connected) {
		create rating_record number: 1 returns: record_list;
		rating_record record <- record_list at 0;

		if rating_db contains_key connected.name {
			record <- rating_db[connected.name];
		} else {
			record.p <- connected;
		}
		
		// calculate new local rating
		// new_rating = old_rating + K1 * res + k2 * (e^(-curr_rating/K3)) where K1, K2 and K3 are configs
		float new_rating <- record.local_rating + (10 * res + 5 * exp(-record.local_rating/10));
		record.local_rating <- new_rating;
		
		// store encounter and increase total number of encounters
		add pair<int, float>(cycle, record.local_rating) at: 0 to: record.encounters;
		if (length(record.encounters) = 100) {
			remove 99 from: record.encounters;
		}
		record.nEncounters <- record.nEncounters + 1;
	
		put record at: record.p.name in: rating_db;
	}
	
	action receive(map<string, rating_record> db, particle from) {
		loop receiving_record over: db.values {
			create rating_record number: 1 returns: record_list;
			rating_record record <- record_list at 0;
			
			if (rating_db contains_key receiving_record.p.name) {
				record <- rating_db[receiving_record.p.name];
			} else {
				record.p <- receiving_record.p;
			}
			
			record.global_ratings[from.name] <- receiving_record.local_rating;
			record.global_rating <- mean(record.global_ratings.values);
						
			put record at: record.p.name in: rating_db;
		}
	}
}