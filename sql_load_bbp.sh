#!/bin/bash 


DATABASE=_ermrest_d5jvfi6oRdmpyTj5YWEkvQ


SIMSCSV=fbsim.csv
STATCSV=fbstat.csv

#BBP_SCHEMA=simulations
BBP_SCHEMA=legacy

create_tables()
{

cat bbp_schema.sql | sed -e "s/{{SIM_SCHEMA}}/${BBP_SCHEMA}/g" | psql ${DATABASE}

}


load_data()
{

cat ${SIMSCSV} | psql -c "COPY ${BBP_SCHEMA}.simulation_base FROM STDIN WITH CSV HEADER" ${DATABASE}

cat ${STATCSV} | psql -c "COPY ${BBP_SCHEMA}.station_results_base FROM STDIN WITH CSV HEADER" ${DATABASE}

}


create_materialized_views()
{

psql ${DATABASE}<<EOF

SET SEARCH_PATH TO ${BBP_SCHEMA};
INSERT INTO simulation 
   SELECT validation_package_version||' : '||simulation_id AS validation_simulation,
          'Simulation '||simulation_id||' with validation package '||validation_package_version||
          ' Broadband version '||Broadband_Version|| 
          ' Velocity model version '||Velocity_model_version|| 
          ' Simulation Started on '||Simulation_Start_Time||
          ' and Ended on '||Simulation_End_Time  AS summary,
   Broadband_Version,
   Velocity_model_version,
   Validation_package_version,
   Simulation_Start_Time,
   Simulation_End_Time,
   Simulation_ID,
   Sim_Spec,
   RotD50_Bias_Plot,
   RotD50_Map_GOF_Plot,
   Respect_Bias_Plot,
   GMPE_Comparison_Bias_Plot,
   RotD50_Dist_Bias_Linear,
   RotD50_Dist_Bias_Log,
   Station_Map_PNG,
   Station_Map_KML,
   Rupture_file_data,
   Rupture_file_PNG 
     FROM simulation_base ;


INSERT INTO station_results 
SELECT 
   validation_package_version||' : '||simulation_id||' : '||station_id AS validation_simulation_station,
   validation_package_version||' : '||simulation_id AS validation_simulation,
   Validation_package_version,
   Simulation_ID,
   'Data for Station '||station_id||' for validation package_version '||Validation_package_version||
   ' and Simulation ID '||Simulation_ID AS summary,
   station_id,
   Velocity_data,
   Velocity_PNG,
   Acceleration_data,
   Acceleration_PNG,
   RotD50_data,
   RotD50_PNG,
   Respect_data,
   Respect_PNG,
   Overlay_PNG
       FROM simulation_base JOIN station_results_base USING (sim_index);

EOF





}


create_views()
{

psql ${DATABASE}<<EOF

SET SEARCH_PATH TO ${BBP_SCHEMA};

DROP VIEW station_results;
CREATE VIEW station_results AS 
   SELECT B.simulation_id,
          B.validation_package_version,
          A.*  
           FROM station_results_base A JOIN simulation B USING (sim_index);

EOF

}

add_annotations()
{



SIM_TOP=(  validation_package_version simulation_id broadband_version velocity_model_version )
STAT_TOP=( validation_package_version simulation_id station_id )


for col in ${SIM_TOP[@]}
do 

psql ${DATABASE}<<EOF
insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','simulation','${col}','comment','["top"]') ;
EOF


done

for col in ${STAT_TOP[@]}
do 

psql ${DATABASE}<<EOF
insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','station_results','${col}','comment','["top"]') ;
EOF

done



SIM_THUMB=( rotd50_bias_plot rotd50_map_gof_plot respect_bias_plot gmpe_comparison_bias_plot rotd50_dist_bias_linear rotd50_dist_bias_log station_map_png rupture_file_png )

SIM_FILE=( sim_spec station_map_kml rupture_file_data )




for col in ${SIM_THUMB[@]}
do

psql ${DATABASE}<<EOF

insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','simulation','${col}','comment','["thumbnail","bottom"]') ;

EOF

done

for col in ${SIM_FILE[@]}
do

psql ${DATABASE}<<EOF

insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','simulation','${col}','comment','["file","bottom"]') ;

EOF

done


STAT_THUMB=( velocity_png acceleration_png rotd50_png respect_png overlay_png )
STAT_FILE=( velocity_data acceleration_data rotd50_data respect_data )


for col in ${STAT_FILE[@]}
do 
psql ${DATABASE}<<EOF
insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','station_results','${col}','comment','["file","bottom"]') ;
EOF
done


for col in ${STAT_THUMB[@]}
do 
psql ${DATABASE}<<EOF
insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','station_results','${col}','comment','["thumbnail","bottom"]') ;
EOF
done


psql ${DATABASE}<<EOF


insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','simulation','validation_simulation','comment','["title","bottom"]') ;
insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','simulation','summary','comment','["summary"]') ;



insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','station_results','validation_simulation_station','comment','["title","bottom"]') ;
insert into _ermrest.model_column_annotation values('${BBP_SCHEMA}','station_results','summary','comment','["summary"]') ;

insert into _ermrest.model_table_annotation values('${BBP_SCHEMA}','simulation_base','comment','["exclude"]');
insert into _ermrest.model_table_annotation values('${BBP_SCHEMA}','station_results_base','comment','["exclude"]');

insert into _ermrest.model_table_annotation values('${BBP_SCHEMA}','station_results','comment','["nested"]');

EOF


}


main()
{

create_tables
load_data
create_materialized_views
add_annotations

}

# ---------------

main