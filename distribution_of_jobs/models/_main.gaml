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
	
	list<job> slow_jobs <- [];
	
	init {
		create particle number: 10;
		seed <- 10.0;
	}
	
	reflex find_slow_jobs {
		slow_jobs <- job where ((each.end_time != 0) and (each.estimated_sequential_processing_time < (each.end_time - each.start_time)));
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
	init {
		seed <- 10.0;
		write seed;
	}
	
	output {
		display main_display {
			grid navigation_cell lines: #black;
			species particle aspect: base;
		}
		
		display chart_display {
			chart "speedup_chart" type: histogram {
				datalist legend value: values;
			}
		}
		
		monitor "Average speedup" value: avg_speedup;
		monitor "Seed" value: seed;
		monitor "Slow jobs" value: length(slow_jobs);
		monitor "Number of finished jobs" value: length(job where (each.end_time != 0));
	}
}