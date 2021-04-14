/**
* Name: main
* Based on the internal empty template. 
* Author: ralle
* Tags: 
*/


model _main

/* Insert your model definition here */
import 'benign.gaml'
import 'uncooperative.gaml'
import 'malicious.gaml'


global {	
	// Particle
	int min_movement_radius <- 10;
	int max_movement_radius <- 25;
	int min_comm_radius <- 5;
	int max_comm_radius <- 20;
	
	int p_broadcast_cycles <- 10;
	int p_classification_cycles <- 10;
	int p_kmeans_iterations <- 500;
	float p_auction_proba <- 0.2;
	int p_lower_expected_time <- 10;
	int p_upper_expected_time <- 10;
	int p_decrease_rating_cycle <- 20;
	float p_decreasing_factor <- 0.99;
	int p_local_rating_w1 <- 10;
	int p_local_rating_w2 <- 5;
	int p_local_rating_w3 <- 10;
	float p_minimum_rating <- 0.1;
	int p_maximum_encounter_length <- 100;
	int p_distance_treshold <- 8;
	
	// Benign
	float b_variance_factor <- 0.1;

	// Malicious
	float m_variance_factor <- 0.1;
	float m_lower_bid_factor <- 0.7;
	
	// Uncooperative
	
	// Charts data
	float benign_rating <- 0.0;
	float malicious_rating <- 0.0;
	list<float> benign_global_ratings <- [];
	list<float> malicious_global_rating <- [];
	float avg_speedup <- 0.0;
	
	list<job> slow_jobs <- [];
	
	reflex find_slow_jobs {
		slow_jobs <- job where ((each.end_time != 0) and (each.estimated_sequential_processing_time < (each.end_time - each.start_time + each.acc_bid_diff)));
	}
	
	reflex set_speedup {
		list<job> jobs <- job where (each != nil and each.end_time != 0);
		list<float> speedups <- [];
		loop j over: jobs {
			float speedup <- 0.0;			
			if (j.start_time = j.end_time) {
				speedup <- j.estimated_sequential_processing_time;
			} else {
				speedup <- j.estimated_sequential_processing_time / (j.end_time - j.start_time + j.acc_bid_diff);
			}
			add speedup at: 0 to: speedups;
		}
		
		avg_speedup <- mean(speedups);
	}

	reflex charts_data when: every(4#cycles) {
		// calculate the average global rating of benign agents
		list<float> benign_ratings;
		loop b over: benign {
			list<float> ratings;
			loop p over: (list<particle>(benign + uncooperative + malicious) where (each.name != b.name)) { //  and each.rating_db[b.name].global_rating != 0
 				if p.rating_db contains_key b.name {
 					add p.rating_db[b.name].global_rating to: ratings; 					
 				}
			}
			add mean(ratings) to: benign_ratings;
		}
		benign_rating <- mean(benign_ratings);
		
		// calculate the average global rating of malicious agents
		list<float> malicious_ratings;
		loop m over: malicious {
			list<float> ratings;
			loop p over: (list<particle>(benign + uncooperative + malicious) where (each.name != m.name)) { //  and each.rating_db[b.name].global_rating != 0
 				if p.rating_db contains_key m.name {
 					add p.rating_db[m.name].global_rating to: ratings; 					
 				}
			}
			add mean(ratings) to: malicious_ratings;
		}
		malicious_rating <- mean(malicious_ratings);
	}
	
	init {
		seed <- 10.0;
		
		create benign number: 30;
		create uncooperative number: 0;
		create malicious number: 10;
	}
}


grid navigation_cell width: 10 height: 10 neighbors: 4 { }

experiment utilizing_trust type: gui {
	// Particle
 	parameter "Minimum Movement Radius" var: min_movement_radius category: "Particle";
 	parameter "Maximum Movement Radius" var: max_movement_radius category: "Particle";
 	parameter "Minimum Communication Radius" var: min_comm_radius category: "Particle";
 	parameter "Maximum Communication Radius" var: max_comm_radius category: "Particle";
 	
 	parameter "Number of cycles between broadcasts" var: p_broadcast_cycles category: "Particle";
 	parameter "Number of cycle between classification" var: p_classification_cycles category: "Particle";
 	parameter "Number of cycles between decreasing ratings" var: p_decrease_rating_cycle category: "Particle";
 	
 	parameter "Number of iterations in kmeans" var: p_kmeans_iterations category: "Particle";
 	parameter "Decreasing factor" var: p_decreasing_factor category: "Particle";
 	
 	parameter "Probability for holding an auction" var: p_auction_proba category: "Particle";
 	parameter "Lower bound for expectected time for auction item" var: p_lower_expected_time category: "Particle";
 	parameter "Upper bound for expectected time for auction item" var: p_upper_expected_time category: "Particle";
 	
 	parameter "Local rating W1" var: p_local_rating_w1 category: "Particle";
 	parameter "Local rating W2" var: p_local_rating_w2 category: "Particle";
 	parameter "Local rating W3" var: p_local_rating_w3 category: "Particle";
 	parameter "Minimum rating gain for interaction" var: p_minimum_rating category: "Particle";
 	parameter "Maximum length of encounter list" var: p_maximum_encounter_length category: "Particle";
 	parameter "Distance between clusters" var: p_distance_treshold category: "Particle";
 	
 	// Malicious
 	parameter "Lower bid factor" var: m_lower_bid_factor category: "Malicious";
 	parameter "Malicious variance factor" var: m_variance_factor category: "Malicious";
 	
 	// Benign
 	parameter "Benign variance factor" var: b_variance_factor category: "Benign";
	
	output {
		display main_display {
			grid navigation_cell lines: #black;
			species benign aspect: base;
			species uncooperative aspect: base;
			species malicious aspect: base;
		}
		
		display chart_display refresh: every(5#cycles) {
			chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
				data "benign rating" value: benign_rating color: #blue;
				data "malicious rating" value: malicious_rating color: #red;
			}
		}
		monitor "Average speedup" value: avg_speedup;
		monitor "Slow jobs" value: length(slow_jobs);
		monitor "Number of jobs" value: length(job);
	}
}