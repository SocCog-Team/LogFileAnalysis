function [ isNHP, short_species_string, full_species_string ] = fn_is_NHP( subject_name )
%FN_IS_NHP Summary of this function goes here
%   Detailed explanation goes here

short_species_string = [];
full_species_string = [];

macaca_mulatta_name_list = {...
	'Curius', ...
	'Flaffus', ...
	'Tesla', ...
	'Linus', ...
	'Magnus', ...
	'Elmo', ...
	'Bacchus', ...
	'Pinocchio', ...
};

is_macaca_mulatta = ismember(subject_name, macaca_mulatta_name_list);

if (is_macaca_mulatta)
	short_species_string = 'NHP';
	full_species_string = 'macaca mulatta';
	isNHP = 1;
else
	short_species_string = 'HP'; % human primate
	full_species_string = 'homo sapiens';
	isNHP = 0;
end

return
end

