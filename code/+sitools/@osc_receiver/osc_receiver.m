classdef osc_receiver < sitools.si_linker
    % osc_receiver.osc_receiver - acquire data from analog input channels and sync some operations with ScanImage
    %
    % Purpose
    % Create a server listening to osc messages and changing file name of
    % saved data in scanimage according to the message body
    %
    % Getting Help
    % Try "doc sitools.osc_receiver" and also look at the help text for the
    % following methods of this function:
    % sitools.osc_receiver.linkToScanImageAPI
    % sitools.osc_receiver.connectToServer
    % sitools.osc_receiver.start
    % sitools.osc_receiver.stop
    % sitools.osc_receiver.loadSettings
    % sitools.osc_receiver.saveCurrentSettings
    %
    %
    % * Quick Start: connect to ScanImage with default settings
    %  a. Start ScanImage
    %  b. Do: osc = sitools.osc_receiver;
    %  c. Send an osc message with text
    %  c. Press "Focus" or "Grab". The file name should change before
    %  acquisition
    %  d. delete(osc) to shut down the osc receiver.
    % 
    %
    % * Create, save, then load a set of acquisition preferences
    % >> osc=sitools.osc_receiver();
    % >> osc.port_number = 2323;  % set the port to listen to
    % >> osc.address='/si_fname';
    % >> osc.saveCurrentSettings('prefsoscrec.mat');
    % >> delete(osc) %Just to prove it works
    %   sitools.osc_receiver is shutting down
    % >> scanimage
    % >> osc=sitools.osc_receiver('prefsoscrec.mat'); % check displayed properies
    %
    %  
    %  c. You can the stop and start the name change at will:
    %  >> osc.stop
    %  >> osc.start
    %
    %
    % KNOWN ISSUES
    %
    % 1)
    % Code is not writen
    %
    % Antonin Blot - London, 2021
    %
    % 
    % Also see:
    % https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
    

    properties (SetAccess=protected, Hidden=false)

        hReceiver % The OSC receiver handle is stored here
        hListener % the osc listener handle
    end 

    properties
        % Saving and data configuration
        % OSC server configuration (these values are read on startup only)
        % CAUTION: Do not edit these values here for your experiment. Change 
        %          the properties in the live object and use the saveCurrentSettings
        %          and loadCurrentSettingsMethods
        
        port_number = 2323;
        address = '/si_fname';
        addDateTime = false;
        verbosity = 1;
        rootPath = 'E:\Data';
        
    end 

    methods

        function obj = osc_receiver(linkToScanImage)
            % sitools.osc_receiver
            %
            % Inputs
            % linkToScanImage - true by default. 
            %           * If true, we attempt to connect to ScanImage so that file names are
            %            changed whenver Focus or Grab are pressed. 
            %           * If linkToScanImage is false, this is not done. Nothing is connectd or 
            %             started. Use this to set parameters. 
            %           * If linkToScanImage is a string, we treat it as a preference file name 
            %             and attempt to load it. 

            if nargin<1
                linkToScanImage=true;
            end

            if ischar(linkToScanImage)
                obj.loadSettings(linkToScanImage)
                linkToScanImage=true;
            end

            if linkToScanImage
                if obj.linkToScanImageAPI
                    obj.listeners{length(obj.listeners)+1} = addlistener(obj.hSI,'acqState', 'PostSet', @obj.startStopAcqWithScanImage);
                end
            else
                fprintf('\nNot connecting to ScanImage \n\n')
            end %if success
        end %constructor

        function changeFileName(obj, messageText)
            if isempty(obj.hSI)
                return
            end
            hSI = obj.hSI;
            
            % parse message to find file name and path
            pathPieces = strsplit(messageText, '/');
            fileName = pathPieces{end};
            if numel(pathPieces) > 1
                setPath = true;
                pathPieces = pathPieces(1:end-1);
                fullPath = strjoin([obj.rootPath , pathPieces], filesep);
                if exist(fullPath, 'file')
                    fprintf('Target path `%s` is an existing file\n', fullPath)
                    fprintf('Will not change the path\n')
                    setPath = false;
                end
                [ok, message, ~] = mkdir(fullPath);
                if ~ok
                    setPath = false;
                    fprintf('Error while creating directory: %s\n', message)
                    fprintf('Will not change the path\n')
                end
                if setPath
                    if obj.verbosity
                        fprintf('Changing save directory to: %s\n', fullPath)
                    end
                    hSI.hScan2D.logFilePath = fullPath;
                end
            end
            
            if obj.addDateTime
                fileName = strcat(datestr(now ,'yyyymmdd_HHMMSS_'), fileName);
            end
            
            if obj.verbosity
                fprintf('Changing file name to: %s\n', fileName)
            end
            hSI.hScan2D.logFileStem = fileName;

            
        end %changeFileName
        
        function varargout=createServer(obj)
            % osc_receiver.createServer - Create the actual server
            %
            
            if ~startsWith(obj.address, '/')
                obj.address = strcat('/', obj.address);
            end
            path2jar = 'E:\code\microscope-control\src\osc_messages';
            version -java
            javaaddpath(fullfile(path2jar, 'javaosctomatlab.jar'));
            import com.illposed.osc.*;
            import java.lang.String
            obj.hReceiver =  OSCPortIn(obj.port_number);
            osc_method = String(obj.address);
            obj.hListener = MatlabOSCListener();
            obj.hReceiver.addListener(osc_method, obj.hListener);
            obj.hReceiver.startListening();
            fprintf('Started server listen to %s of port %d\n', obj.address, obj.port_number)
            success=true;
            
            if nargout>0
                varargout{1}=success;
            end
            disp('ready to go')
        end

        % Declare external methods
        loadSettings(obj,fname)
        saveCurrentSettings(obj,fname)
    end % Close methods



    methods (Hidden)
        % Declare external hidden methods

        function delete(obj)
            fprintf('sitools.osc_receiver is shutting down\n')
            fprintf('This will throw a SocketException that matlab does not manage to catch\n')
            if ~isempty(obj.hReceiver)
                obj.hReceiver.stopListening();
                obj.hReceiver.close();
            end
            %delete(receiver);
            cellfun(@delete,obj.listeners)
            fprintf('sitools.osc_receiver is closed\n')
        end % destructor





        % -----------------------------------------------------------
        % Callbacks
        function startStopAcqWithScanImage(obj,~,~)
            % If ScanImage is connected and it starts imaging then
            % the file name is changed starts.
            if isempty(obj.hSI)
                if obj.verbosity
                    fprintf('No link to scanimage. Do nothing\n')
                end
                return
            end
            if isempty(obj.hReceiver)
                if obj.verbosity
                    fprintf('Server not started. Do nothing\n')
                end
                return
            end
            switch obj.hSI.acqState 
                case {'focus','loop', 'grab'}
                    msg = obj.hListener.getMessageArgumentsAsString();
                    if ~isempty(msg)
                        if obj.verbosity > 1
                            fprintf('The last message received was %s\n', msg)
                            fprintf('Changing file name\n')
                        end
                        obj.changeFileName(char(msg))
                    else
                        if obj.verbosity
                            fprintf('There was no OSC message\n')
                        end
                    end
                case 'idle'
                    % do nothing for now
            end
        end % startStopAcqWithScanImage


    end % Close hidden methods  

end % Close sitools.osc_receiver
