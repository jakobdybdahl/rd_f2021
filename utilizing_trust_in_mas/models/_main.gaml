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
	
	init {
		create benign number: 30;
		create uncooperative number: 10;
		create malicious number: 30;
	}
}


grid navigation_cell width: 50 height: 50 neighbors: 4 { }

experiment utilizing_trust type: gui {
	output {
		display main_display {
			grid navigation_cell lines: #black;
			species benign aspect: base;
			species uncooperative aspect: base;
			species malicious aspect: base;
		}
	}
}