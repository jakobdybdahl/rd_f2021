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
	int p_broadcast_cycles <- 10;
	int p_decrease_rating_cycle <- 20;
	float p_decreasing_factor <- 0.99;
	int p_maximum_encounter_length <- 100;
	
	// rating
	int p_rating_gain <- 10;
	float p_local_rating_w1 <- 2.5;
	int p_local_rating_w2 <- 5;
	int p_local_rating_w3 <- 10;
	float p_minimum_rating <- 0.5;
	
	// classfification
	int p_classification_cycles <- 10;
	int p_kmeans_iterations <- 50;
	int p_distance_treshold <- 2;
		
	// Particles
	int comm_radius <- 25;
	int number_of_particles <- 100;
	float fraction_of_malicious <- 0.2;
	
	// Charts data
	float benign_rating <- 0.0;
	float malicious_rating <- 0.0;
	float avg_speedup <- 0.0;
	float avg_number_of_work_units_distributed <- 0.0;
	float avg_speedup_diff <- 0.0;
	float estimated_maliciousness <- 0.0;
	float f1 <- 0.0;
	
	list<job> slow_jobs <- [];
	
	string filename <- '';
	
//	reflex find_slow_jobs {
//		// slow_jobs <- job where ((each.end_time != 0) and (each.estimated_sequential_processing_time < (each.end_time - each.start_time + each.acc_bid_diff)));
//		slow_jobs <- job where ((each.end_time != 0) and (each.estimated_sequential_processing_time < (each.end_time - each.start_time)));
//	}
	
	reflex set_distribution_percentage  {
		list<job> jobs <- job where (each != nil and each.end_time != 0);
		list<float> results <- [];
		loop j over: jobs {
			float res <- (length(j.work_units) * j.work_units_processed_by_self) / 100;
			add res at: 0 to: results;
		}
		avg_number_of_work_units_distributed <- 1 - mean(results);
	}
	
	reflex set_speedup {	
		list<job> jobs <- job where (each != nil and each.end_time != 0);
		avg_speedup <- mean(jobs collect each.actual_speedup);
		avg_speedup_diff <- mean(jobs collect abs(each.expected_speedup - each.actual_speedup));
		estimated_maliciousness <-  mean(jobs collect (each.actual_speedup / each.expected_speedup)); // only for malicious
	}
	
	reflex charts_data  {
		// calculate the average global rating of benign agents
		list<float> benign_ratings;
		
		int true_positive <- 0; // Rightly classified benign.
		int true_negative <- 0; // Right classificed malicious
		int false_positive <- 0; // Wrongly classified benign
		int false_negative <- 0; // Wrongly classified malicious
				
		loop b over: benign {
			list<float> ratings;
			loop p over: (list<particle>(benign + uncooperative + malicious) where (each.name != b.name)) { //  and each.rating_db[b.name].global_rating != 0
 				if p.rating_db contains_key b.name {
 					add p.rating_db[b.name].neighbourhood_rating_mean to: ratings; 					
 				}
			}
			add mean(ratings) to: benign_ratings;
			
			if(!empty(b.malicious_particles)) {
				loop m over: b.malicious_particles {
					if(first(m.name) = 'm' ) {
						// Rightly classified
						true_negative <- true_negative + 1;
					} else {
						// Wrongly classified
						false_negative <- false_negative + 1;
					}
				}
			}
			
			loop be over: b.benign_particles {
				if(first(be.name) = 'b' ) {
					// Rightly classified
					true_positive <- true_positive + 1;
				} else {
					// Wrongly classified
					false_positive <- false_positive + 1;
				}
			}
		}
		benign_rating <- mean(benign_ratings);
		
		// calculate the average global rating of malicious agents
		list<float> malicious_ratings;
		loop m over: malicious {
			list<float> ratings;
			loop p over: (list<particle>(benign + uncooperative + malicious) where (each.name != m.name)) { 
 				if p.rating_db contains_key m.name {
 					add p.rating_db[m.name].neighbourhood_rating_mean to: ratings; 					
 				}
			}
			add mean(ratings) to: malicious_ratings;
			
			if(!empty(m.malicious_particles)) {
				loop mp over: m.malicious_particles {
					if(first(mp.name) = 'm' ) {
						// Rightly classified
						true_negative <- true_negative + 1;
					} else {
						// Wrongly classified
						false_negative <- false_negative + 1;
					}
				}
			}

			
			loop be over: m.benign_particles {
				if(first(be.name) = 'b' ) {
					// Rightly classified
					true_positive <- true_positive + 1;
				} else {
					// Wrongly classified
					false_positive <- false_positive + 1;
				}
			}
		}
		malicious_rating <- mean(malicious_ratings);
		
//		write " ----------- ";
//		write "TP: " + true_positive;
//		write "FP: " + false_positive;
//		write "TN: " + true_negative;
//		write "FN: " + false_negative;
		
		if( true_positive != 0 or false_positive != 0 or false_negative != 0) {
			f1 <- true_positive / ( true_positive + 1/2 * (false_positive + false_negative));			
		}

	}
//	
	reflex save {
		save [cycle, malicious_rating, benign_rating, f1, avg_speedup, avg_number_of_work_units_distributed]  to: "data/distance_threshold/distance_" + p_distance_treshold + ".csv" type: "csv" rewrite: false;
	}
	
	init {   
		create benign number: number_of_particles * (1 - fraction_of_malicious);
		create malicious number: number_of_particles * fraction_of_malicious;
	}
}


grid navigation_cell width: 10 height: 10 neighbors: 4 { }

experiment "Number of Malicious" type: batch repeat: 10 until: cycle = 1000 {
//    parameter 'Number of malicious:' var: fraction_of_malicious among: [ 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9 ];
	parameter 'Distance Threshold' var: p_distance_treshold among: [ 7, 8, 9, 10, 11, 12, 13, 14];
}

experiment utilizing_trust type: gui {
	// Particle
 	parameter "Communication Radius" var: comm_radius category: "Particle";
 	
 	parameter "Number of cycles between broadcasts" var: p_broadcast_cycles category: "Particle";
 	parameter "Number of cycle between classification" var: p_classification_cycles category: "Particle";
 	parameter "Number of cycles between decreasing ratings" var: p_decrease_rating_cycle category: "Particle";
 	
 	parameter "Number of iterations in kmeans" var: p_kmeans_iterations category: "Particle";
 	parameter "Decreasing factor" var: p_decreasing_factor category: "Particle";
 	
 	parameter "Local rating W1" var: p_local_rating_w1 category: "Particle";
 	parameter "Local rating W2" var: p_local_rating_w2 category: "Particle";
 	parameter "Local rating W3" var: p_local_rating_w3 category: "Particle";
 	parameter "Minimum rating gain for interaction" var: p_minimum_rating category: "Particle";
 	parameter "Maximum length of encounter list" var: p_maximum_encounter_length category: "Particle";
 	parameter "Distance between clusters" var: p_distance_treshold category: "Particle";
 	
//	reflex savedata {
//		save [cycle, malicious_rating, benign_rating]  to: "save_data.csv" type: "csv" rewrite: false;
//	}
	
	output {
//		display main_display {
//			grid navigation_cell lines: #black;
//			species benign aspect: base;
//			species uncooperative aspect: base;
//			species malicious aspect: base;
//		}
		
		display rating_chart_display refresh: every(5#cycles) {
			chart "Rating" type: series size: {1,0.5} position: {0, 0} {
				data "benign rating" value: benign_rating color: #blue;
				data "malicious rating" value: malicious_rating color: #red;
			}
			
			chart "F1" type: series size: {1,0.5} position: {0, 50} {
				data "F1" value: f1 color: #blue;
			}
		}
		
		monitor "Average speedup" value: avg_speedup;
		monitor "Average speedup difference" value: avg_speedup_diff;
		monitor "Slow jobs" value: length(slow_jobs);
		monitor "Number of jobs" value: length(job);
		monitor "Percentage of work units distributed" value: avg_number_of_work_units_distributed;
		monitor "F1-score" value: f1;
		monitor "Malciousness" value: estimated_maliciousness;
	}
}

//experiment multiple_simulations type: gui {
//	parameter 'Number of benigns' var: number_of_benign init: 30 category: 'Environment and Population';
//	parameter 'Number of malicious' var: number_of_malicious init: 0 category: "Environment and Population";
//	
//	
//	init {
//		create _main_model with: [number_of_benign::30, number_of_malicious::6];
//		create _main_model with: [number_of_benign::30, number_of_malicious::12];
//		create _main_model with: [number_of_benign::30, number_of_malicious::20];
//	}
//	
//	permanent {
//		display Comparison background: #white {
//			chart "Speedup" type: series {
//				loop s over: simulations {
//					data "Speedup " + int(s) value: s.avg_speedup color: s.color marker: false style: line thickness: 5;
//				}
//			}
//		}
//	}
	
//	output {
//		layout #split editors: false consoles: false tabs: false tray: false navigator: false;
//		display "Test" refresh: every(5#cycles) {
////			chart "Rating " + int(simulation) + ": (" + number_of_benign + "/" + number_of_malicious + ")" type: series size: {1,0.5} position: {0, 0} {
////				data "benign rating" value: benign_rating color: #blue;
////				data "malicious rating" value: malicious_rating color: #red;
////			}
////			chart "F1" type: series size: {1,0.5} position: {0, 50} {
////				data "F1" value: f1 color: #blue;
////			}
//			chart "Speedup" + ": (" + number_of_benign + "/" + number_of_malicious + ")" type: series {
//				data "Average speedup " + int(simulation) value: avg_speedup;
//			}
//		}
//	}
//}
