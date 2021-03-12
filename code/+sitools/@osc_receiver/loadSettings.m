function loadSettings(obj,fname)
    % osc_receiver.loadSettings(fname) - load settings file
    %
    % Purpose
    % Load settings and replace existing property values
    % with those from the loaded structure. This is used to save
    % values as a preference file so they can be quickly
    % re-applied. Use osc_receiver.saveCurrentSettings to create the
    % file. 
    %
    % The following fields will be replaced: port_number,
    % address.
    %
    %
    % Inputs
    % fname - Relative or absolute path to the .mat file we will
    %         load data from. The file should contain a structure
    %         called "metaData" with the fields listed above.
    %         "fname" may also be a valid structure
    % 
    % Examples:
    % >> osc.loadSettings('hello_meta.mat')
    %   All settings updated
    % >> load('hello_meta.mat')
    % >> osc.loadSettings(metaData)
    %   All settings updated
    %

    if ischar(fname)
        load(fname)
        if ~exist('metaData','var')
            fprintf('No variable "metaData" found in file %s\n', fname)
            return
        end
    elseif isstruct(fname)
        metaData = fname;
    else
        fprintf('osc_receiver.loadSettings - Input variable should be a string or a struct\n')
        return
    end


    fieldsToApply = {'port_number', 'address'};
    n=0;

    for ii=1:length(fieldsToApply)
        if ~isfield(metaData,fieldsToApply{ii})
            fprintf('No field "%s" found in loaded structure. Skipping!\n', fieldsToApply{ii})
            continue
        end
        obj.(fieldsToApply{ii}) = metaData.(fieldsToApply{ii});
        n=n+1;
    end

    if n==length(fieldsToApply)
        fprintf('All settings updated\n')
    end


end % loadSettings