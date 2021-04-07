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
	float avg_speedup <- 0.0;
	
	init {
		create my_agent number: 5;
	}
	
	reflex set_speedups {
		list<job> jobs <- job where (each != nil and each.end_time != 0);
		list<float> speedups <- [];
		loop j over: jobs {
			float speedup <- 0.0;			
			if (j.start_time = j.end_time) {
				speedup <- j.estimated_sequential_processing_time;
			} else {
				speedup <- j.estimated_sequential_processing_time / (j.end_time - j.start_time);
			}
			add speedup at: 0 to: speedups;
		}
		
		avg_speedup <- mean(speedups);
		
		legend <- distribution_of (speedups) at 'legend';
		values <- distribution_of (speedups) at 'values';
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
			
			monitor "Average speedup" value: avg_speedup;
		}
	}