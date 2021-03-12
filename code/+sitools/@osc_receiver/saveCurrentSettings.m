function saveCurrentSettings(obj,fname)
    % osc_recorder.saveCurrentSettings(fname) - save settings file
    %
    % Purpose
    % Writes the current receiver settings to a MATLAB structure.
    % This method is used to save settings
    % so that they can be re-applied later using the method
    % osc_recorder.loadSettings
    %
    % The created file will contains the fields: fname, port_numer,
    % address.
    %
    % Inputs
    % fname - Relative or absolute path to the .mat file we will
    %         save data to. Existing files of the same name will be
    %         over-written without warning.
    %
    % Example
    % obj.saveCurrentSettings('myFileName')

    metaData.port_number = obj.port_number;
    metaData.fname = obj.fname;
    metaData.address = obj.address;

    save(fname,'metaData')

end % saveCurrentSettings
