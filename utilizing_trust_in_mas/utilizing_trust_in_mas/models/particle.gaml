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
	int broadcast_cycles <- p_broadcast_cycles;
	
	int computing_slots <- 1;
	float computing_end <- #infinity;
	float computing_start <- 0.0;
	float current_bid <- 0.0;
	particle computing_for <- nil;
	int current_expection <- 0;
	
	rgb default_color <- #blue;
	rgb connected_color <- #green;
	
	list<string> benign_particles <- nil;
	list<string> malicious_particles <- nil;
	int distance_treshold <- p_distance_treshold;
	
	list in_connection_radius -> (agents_at_distance(comm_radius)) of_generic_species particle;
	list connected_particles -> in_connection_radius where (each.in_connection_radius contains self);

	map<string, rating_record> rating_db <- [];
	
	init {
		location <- my_cell.location;
	}
	
	reflex move {
		do wander(1.0, 100.0, bounds);
	}
	
	reflex auction when: flip(p_auction_proba) {		
		particle current_winner <- nil;
		int lowest_bid <- int(#infinity);
		
		if(!empty(connected_particles)) {
			loop connected over: connected_particles {
				int bid <- connected.bid(rnd(p_lower_expected_time, p_upper_expected_time));
				if bid < lowest_bid {
					current_winner <- connected;
					lowest_bid <- bid;
				}
			}
			
			if lowest_bid != #infinity and current_winner != nil {
				// TODO should we store any encounter here, or first when we rate?
				// rating_db[current_winner.name].latestEncounter <- cycle;
				ask current_winner {
					do start_computing(lowest_bid, myself);
				}
			}
		}
	}
	
	reflex broadcast when: every(p_broadcast_cycles#cycles) {
		loop connected over: connected_particles {
			ask connected {
				do receive(myself.rating_db where (each.local_rating != 0), myself);
			}
		}
	}
	
	reflex classify when: every(p_classification_cycles#cycles) {
		list<list> kmeans_init <- nil;
		list<string> names <- nil;
		list<point> points <- nil;
		list<string> cluster_one_names <- nil;
		list<string> cluster_two_names <- nil;
		
		loop record over: rating_db.values {
			float local_mean <- mean(record.encounters.values);
			float global_mean <- mean(record.global_ratings.values);
			
			if (local_mean != 0.0 and global_mean != 0.0) {
				add [local_mean, global_mean] to: kmeans_init;
				add record.p.name to: names;
				add point(local_mean, global_mean) to: points;
			}
		}
		
		if length(kmeans_init) < 2 {
			return;
		}
		
		list<list<int>> kmeans_result <- kmeans(kmeans_init, 2, p_kmeans_iterations);
		
		list<point> cluster_one_points <- nil;
		list<point> cluster_two_points <- nil;
		
		loop index over: kmeans_result[0] {
			add rating_db[names[index]].p.name to: cluster_one_names;
			add points[index] to: cluster_one_points;
		}
		
		loop index over: kmeans_result[1] {
			add rating_db[names[index]].p.name to: cluster_two_names;
			add points[index] to: cluster_two_points;
		}
		
		point mean_cluster_one <- mean(cluster_one_points);
		point mean_cluster_two <- mean(cluster_two_points);
		
		if distance_to(mean_cluster_one, mean_cluster_two) > distance_treshold {
			if mean_cluster_one >= mean_cluster_two { // what if only one component of the point is higher?
				benign_particles <- cluster_one_names;
				malicious_particles <- cluster_two_names;
			} else {
				malicious_particles <- cluster_one_names;
				benign_particles <- cluster_two_names;
			}
			
		} else {
			malicious_particles <- nil;
			benign_particles <- cluster_one_names + cluster_two_names;
		}
		
		cluster_one_names <- nil;
		cluster_two_names <- nil;
		 
		if self.name = 'benign0' {
			write "--------------------";
			write "----- MEANS -----";
			write "cluster 1: " + mean_cluster_one;
			write "cluster 2: " + mean_cluster_two;
			write "dist: " + distance_to(mean_cluster_one, mean_cluster_two);
			write "----- BENIGN -----";
			loop p over: benign_particles {
				rating_record r <- rating_db[p];
				write p;
				write "-- " + mean(r.encounters.values);
				write "-- " + mean(r.global_ratings.values);
			}
			write "----- MAL --------";
			loop p over: malicious_particles {
				rating_record r <- rating_db[p];
				write p;
				write "-- " + mean(r.encounters.values);
				write "-- " + mean(r.global_ratings.values);
			}
		}

	}
	
	reflex decrease when: every(p_decrease_rating_cycle#cycles) {
		loop record over: rating_db.values {
			loop encounter_key over: record.encounters.keys {
				if (cycle - encounter_key > 500) {
					record.encounters[encounter_key] <- record.encounters[encounter_key] * p_decreasing_factor;
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

	action rate(float res, particle connected) {
		create rating_record number: 1 returns: record_list;
		rating_record record <- record_list at 0;

		if rating_db contains_key connected.name {
			record <- rating_db[connected.name];
		} else {
			record.p <- connected;
		}
		
		// calculate new local rating
		// new_rating = W1 * res + W2 * (e^(-curr_rating/W3)) where W1, W2 and W3 are configs
		float new_rating <- (p_local_rating_w1 * res + p_local_rating_w2 * exp(-record.local_rating/p_local_rating_w3));
		
		// store encounter and increase total number of encounters
		record.encounters[cycle] <- new_rating < 0 ? p_minimum_rating : new_rating;
		record.local_rating <- mean(record.encounters.values);
		
		if (length(record.encounters) > p_maximum_encounter_length) {
			int min_key <- min(record.encounters.keys);
			remove key: min_key from: record.encounters;
		}
		
		record.nEncounters <- record.nEncounters + 1;
	
		put record at: record.p.name in: rating_db;
	}
	
	action receive(list<rating_record> db, particle from) {
		// TODO: Check if rating_db contains key
		// rating_db[from.name].latestEncounter <- cycle;
		loop receiving_record over: db {
			create rating_record number: 1 returns: record_list;
			rating_record record <- record_list at 0;
			
			if (rating_db contains_key receiving_record.p.name) {
				record <- rating_db[receiving_record.p.name];
			} else {
				record.p <- receiving_record.p;
			}
			
			record.global_ratings[from.name] <- mean(receiving_record.encounters.values);
			record.global_rating <- mean(record.global_ratings.values);
						
			put record at: record.p.name in: rating_db;
		}
	}
}