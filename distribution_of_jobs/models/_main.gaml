/**
* Name: mymodel
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model mymodel

import 'submitter.gaml'

global {
	init {
		create my_agent number: 5;
	}
}

grid navigation_cell width: 10 height: 10 neighbors: 4 { }

experiment distributing_jobs type: gui {
		output {
			display main_display {
				grid navigation_cell lines: #black;
				species my_agent aspect: base;
			}
		}
	}