
CREATE SCHEMA {{SIM_SCHEMA}};

SET SEARCH_PATH TO {{SIM_SCHEMA}};



DROP TABLE simulation_base;
CREATE TABLE simulation_base(
   sim_index int PRIMARY KEY,
   Broadband_Version text,
   Velocity_model_version text,
   Validation_package_version text,
   Simulation_Start_Time text,
   Simulation_End_Time text,
   Simulation_ID text,
   Sim_Spec text,
   RotD50_Bias_Plot text,
   RotD50_Map_GOF_Plot text,
   Respect_Bias_Plot text,
   GMPE_Comparison_Bias_Plot text,
   RotD50_Dist_Bias_Linear text,
   RotD50_Dist_Bias_Log text,
   Station_Map_PNG text,
   Station_Map_KML text,
   Rupture_file_data text,
   Rupture_file_PNG text
);


DROP TABLE station_results_base;
CREATE TABLE station_results_base(
   sim_index int REFERENCES simulation_base(sim_index),
   station_id text,
   Velocity_data text, 
   Velocity_PNG  text, 
   Acceleration_data text,
   Acceleration_PNG text,
   RotD50_data text,
   RotD50_PNG text,
   Respect_data text,
   Respect_PNG text,
   Overlay_PNG text,
   PRIMARY KEY(sim_index,station_id)
);



DROP TABLE simulation CASCADE;
CREATE TABLE simulation(
   validation_simulation text PRIMARY KEY,
   summary text,
   Broadband_Version text,
   Velocity_model_version text,
   Validation_package_version text,
   Simulation_Start_Time text,
   Simulation_End_Time text,
   Simulation_ID text,
   Sim_Spec text,
   RotD50_Bias_Plot text,
   RotD50_Map_GOF_Plot text,
   Respect_Bias_Plot text,
   GMPE_Comparison_Bias_Plot text,
   RotD50_Dist_Bias_Linear text,
   RotD50_Dist_Bias_Log text,
   Station_Map_PNG text,
   Station_Map_KML text,
   Rupture_file_data text,
   Rupture_file_PNG text
);


DROP TABLE station_results;
CREATE TABLE station_results(
   validation_simulation_station text PRIMARY KEY,
   validation_simulation text REFERENCES simulation,
   Validation_package_version text,
   Simulation_ID text,
   summary text,
   station_id text,
   Velocity_data text, 
   Velocity_PNG  text, 
   Acceleration_data text,
   Acceleration_PNG text,
   RotD50_data text,
   RotD50_PNG text,
   Respect_data text,
   Respect_PNG text,
   Overlay_PNG text
);
