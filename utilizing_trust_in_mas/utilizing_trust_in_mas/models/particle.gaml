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
import 'component/submitter.gaml'
import 'component/worker.gaml'

species particle skills: [moving] {
	navigation_cell my_cell <- one_of(navigation_cell);
	int broadcast_cycles <- p_broadcast_cycles;
	
	int computing_slots <- 1;
	float computing_end <- #infinity;
	float computing_start <- 0.0;
	float current_bid <- 0.0;
	particle computing_for <- nil;
	int current_expection <- 0;
	
	rgb default_color <- #blue;
	rgb connected_color <- #green;
	
	list<particle> benign_particles <- nil;
	list<particle> malicious_particles <- nil;
	list<particle> unclassified_particles <- nil;
	
	int distance_treshold <- p_distance_treshold;
	
	list in_connection_radius -> (agents_at_distance(comm_radius)) of_generic_species particle;
	list connected_particles -> in_connection_radius where (each.in_connection_radius contains self);
	
	worker worker <- nil;
	submitter submitter <- nil;

	map<string, rating_record> rating_db <- [];
	
	init {
		location <- my_cell.location;
		
		create submitter {
			myself.submitter <- self;
			self.particle <- myself;
		}
		
		create worker {
			myself.worker <- self;
			self.particle <- myself;
		}
	}
	
	reflex move {
		do wander(1.0, 100.0);
	}
	
	reflex broadcast when: every(p_broadcast_cycles#cycles) {
		loop connected over: connected_particles {
			ask connected {
				do receive(myself.rating_db where (each.local_rating_mean != 0), myself);
			}
		}
	}
	
	reflex classify when: every(p_classification_cycles#cycles) {
		list<list> kmeans_init <- nil;
		list<particle> particles <- nil;
		list<point> points <- nil;
		list<particle> cluster_one_names <- nil;
		list<particle> cluster_two_names <- nil;
		
		loop record over: rating_db.values {
			float local_mean <- record.local_rating_mean;
			float neighbourhood_mean <- record.neighbourhood_rating_mean;
			
			if (local_mean != 0.0 and neighbourhood_mean != 0.0) {
				add [local_mean, neighbourhood_mean] to: kmeans_init;
				add record.p to: particles;
				add point(local_mean, neighbourhood_mean) to: points;
			}
		}
		
		if length(kmeans_init) < 2 {
			return;
		}
		
		list<list<int>> kmeans_result <- kmeans(kmeans_init, 2, p_kmeans_iterations);
		
		list<point> cluster_one_points <- nil;
		list<point> cluster_two_points <- nil;
		
		loop index over: kmeans_result[0] {
			add rating_db[particles[index].name].p to: cluster_one_names;
			add points[index] to: cluster_one_points;
		}
		
		loop index over: kmeans_result[1] {
			add rating_db[particles[index].name].p to: cluster_two_names;
			add points[index] to: cluster_two_points;
		}
		
		point mean_cluster_one <- mean(cluster_one_points);
		point mean_cluster_two <- mean(cluster_two_points);
		
		if distance_to(mean_cluster_one, mean_cluster_two) > distance_treshold {
			unclassified_particles <- nil;
			if mean_cluster_one >= mean_cluster_two { 
				benign_particles <- cluster_one_names;
				malicious_particles <- cluster_two_names;
			} else {
				malicious_particles <- cluster_one_names;
				benign_particles <- cluster_two_names;
			}
			
		} else {
			unclassified_particles <- cluster_one_names + cluster_two_names;
			benign_particles <- nil;
			malicious_particles <- nil;
		}
		
		cluster_one_names <- nil;
		cluster_two_names <- nil;
		 
//		if self.name = 'benign0' {
			write "--------------------";
			write "------ " + self.name + " ------";
			write "----- MEANS -----";
			write "cluster 1: " + mean_cluster_one;
			write "cluster 2: " + mean_cluster_two;
			write "dist: " + distance_to(mean_cluster_one, mean_cluster_two);
			write "----- BENIGN -----";
			loop p over: benign_particles {
				rating_record r <- rating_db[p.name];
				write p;
				write "-- " + r.local_rating_mean;
				write "-- " + r.neighbourhood_rating_mean;
			}
			write "----- MAL --------";
			loop p over: malicious_particles {
				rating_record r <- rating_db[p.name];
				write p;
				write "-- " + r.local_rating_mean;
				write "-- " + r.neighbourhood_rating_mean;
			}
//		}

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
		draw circle(comm_radius) color: #transparent border: #lightblue; 
	}

	action rate(float res, particle connected) {
		rating_record record <- nil;
		create rating_record {
			record <- self;
		}

		if rating_db contains_key connected.name {
			record <- rating_db[connected.name];
		} else {
			record.p <- connected;
		}
				
		// calculate new local rating;
		float new_rating <- 0.0;
		float rating_bonus <-  (p_local_rating_w2 * exp(-record.local_rating_mean/p_local_rating_w3));
		// If good result:
		if(res >= 0) {
			new_rating <- p_rating_gain + rating_bonus;
		} else if(res > -1 and res < 0) {
			// if okay-ish result:
			new_rating <-  -p_local_rating_w1*res^2 + p_rating_gain + rating_bonus;
		} else {
			// if bad result
			new_rating <- p_minimum_rating;
		}
		
		// store encounter and increase total number of encounters
		record.encounters[cycle] <- new_rating;
		
		if (length(record.encounters) > p_maximum_encounter_length) {
			int min_key <- min(record.encounters.keys);
			remove key: min_key from: record.encounters;
		}
		
		record.nEncounters <- record.nEncounters + 1;
		record.local_rating_mean <- mean(record.encounters.values);
		
		put record at: record.p.name in: rating_db;
	}
	
	action receive(list<rating_record> db, particle from) {
		if (rating_db contains_key from.name) {
			rating_db[from.name].latestEncounter <- cycle;
		}

		loop receiving_record over: db {
			rating_record record <- nil;
			create rating_record {
				record <- self;
			}
			
			if (rating_db contains_key receiving_record.p.name) {
				record <- rating_db[receiving_record.p.name];
			} else {
				record.p <- receiving_record.p;
			}
			
			record.neighbourhood_ratings[from.name] <- mean(receiving_record.encounters.values);
			record.neighbourhood_rating_mean <- mean(record.neighbourhood_ratings);
			
			put record at: record.p.name in: rating_db;
		}
	}
}