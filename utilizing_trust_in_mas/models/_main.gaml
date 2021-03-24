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
	int min_movement_radius <- 10;
	int max_movement_radius <- 25;
	int min_comm_radius <- 5;
	int max_comm_radius <- 20;
	
	//list<particle> particles <- list<particle>(benign + uncooperative + malicious);
	
	float benign_rating <- 0.0;
	float malicious_rating <- 0.0;
	
	reflex charts_data {
		//write length(particles);
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
		create benign number: 30;
		create uncooperative number: 0;
		create malicious number: 30;
	}
}


grid navigation_cell width: 10 height: 10 neighbors: 4 { }

experiment utilizing_trust type: gui {
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
	}
}