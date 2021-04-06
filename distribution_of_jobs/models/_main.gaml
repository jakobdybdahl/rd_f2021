/**
* Name: mymodel
* Based on the internal empty template. 
* Author: Jakob Dybdahl
* Tags: 
*/


model mymodel

import 'submitter.gaml'

global {
	list<string> legend <- [];
	list<unknown> values <- [];
	
	init {
		create my_agent number: 5;
	}
	
	reflex set_jobs {
		list<job> jobs <- job where (each != nil and each.end_time != 0);
		legend <- distribution_of (jobs collect (each.estimated_sequential_processing_time / (each.end_time - each.start_time))) at 'legend';
		values <- distribution_of (jobs collect (each.estimated_sequential_processing_time / (each.end_time - each.start_time))) at 'values';
	}
}

grid navigation_cell width: 10 height: 10 neighbors: 4 { }

experiment distributing_jobs type: gui {
		output {
			display main_display {
				grid navigation_cell lines: #black;
				species my_agent aspect: base;
			}
			
			display chart_display {
				chart "speedup_chart" type: histogram {
					datalist legend value: values;
				}
			}
		}
	}