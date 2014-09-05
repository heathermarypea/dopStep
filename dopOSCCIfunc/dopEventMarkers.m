function [dop,okay,msg] = dopEventMarkers(dop_input,varargin) % ,downsample_rate)
% dopOSCCI3: dopEventMarkers
%
% notes:
% create an event-marker channel
%
% * not yet implemented (17-Dec-2013)
%
% Use:
%
% dop = dopEventMarkers(dop);
%
% where:
% > Inputs:
% - dop = dop matlab structure
%
% > Outputs: (note, varargout - therefore optional or as many as you want)
% - dop = dop matlab sructure
%
% - okay = logical (0 or 1) okay for dopOSCCI to use
% - msg = message about success of function
%
% Created: 17-Dec-2013 NAB
% Last edit:
% 9-Aug-14 NAB
% 31-Aug-14 NAB should now work after dopEventChannels is called
% 04-Sep-14 NAB msg & wait_warn updates
% 05-Sep-14 NAB added dopPeriodCheck

[dop,okay,msg,varargin] = dopSetBasicInputs(dop_input,varargin);
msg{end+1} = sprintf('Run: %s',mfilename);

try
    if okay
        dopOSCCIindent; % dopOSCCIindent('run',dop.tmp.comment);%fprintf('\nRunning %s:\n',mfilename);
%         inputs.turnOff = {'comment'};
        inputs.varargin = varargin;
        inputs.defaults = struct(...
            'file',[],...
            'msg',1,...
            'wait_warn',0,...
            'event_height',[],... % really needs to be specified but could set to 1000
            'event_channels',[], ... % could take last column by default
            'sample_rate',[] ... % not critical
            );
        inputs.required = ...
            {'event_height','event_channels'};
        [dop,okay,msg] = dopSetGetInputs(dop_input,inputs,msg);
        
        %% check inputs
        if okay && size(dop.tmp.data,3) > 1
            okay = 0;
            msg{end+1} = sprintf(['''dop.data.use'' variable has 3rd'...
                ' dimension - probably already epoched.'...
                'set ''dop.data.use'' to earlier data structure, ' ...
                'e.g., dop.data.raw or dop.data.down or dop.data.trim',...
                '\n(%s: %s)'], size(dop.tmp.data,3),mfilename,dop.file);
               
            dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);
        elseif okay && size(dop.tmp.data,2) == 2 && ~isfield(dop.data,'event')
            okay = 0;
            msg{end+1} = sprintf(['Only 2 data columns, assuming left & right' ...
                ' signal data, and ''dop.data.event'' doesn''t exist.' ...
                ' Need event data somewhere for %s function.',...
                '\n(%s: %s)'], mfilename,mfilename,dop.file);
            dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);

        end
        
        
        if okay
            if isfield(dop.data,'event_plot')
                msg{end+1} = '''dop.data.event_plot'' found - better to run this before dopEventChannel';
                dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);
                % not sure it's worth doing this but after using
                % dopEventChannel this data is set to ones and zeros so the
                % marker height and difference calculations aren't needed
                % - I'm not sure whether dopEventChannel is a sensible
                % thing 27-Aug-2014 NAB
                dop.event.samples = find(dop.tmp.data(:,strcmp(dop.data.channel_labels,'event')));
                if isempty(dop.event.samples)
                    okay = 0;
                    msg{end+1} = sprintf(['No events found in - could be that'...
                        ' you''ve changed the length of the data after'...
                        ' calling the ''dopEventChannels'' function\n(%s: %s)'],...
                        mfilename,dop.file);
                    dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);
                end
            elseif size(dop.tmp.data,2) >= max([dop.use.signal_channels dop.use.event_channels])
                dop.tmp.ev = dop.tmp.data(:,dop.tmp.event_channels) > dop.tmp.event_height;
            else
                % may or may not be multiple event channels, not sure this
                % is programmed to cope with it but perhaps eventually
                % 12-Aug-2014
                dop.tmp.ev = dop.tmp.data(:,strcmp(dop.data.channel_labels,'event')) > dop.tmp.event_height;
            end
            if ~isfield(dop.data,'event_plot')
                if ~sum(dop.tmp.ev)
                    okay = 0;
                    msg{end+1} = sprintf(['No events found greater than %u',...
                        '\n(%s: %s)'], dop.tmp.event_height,mfilename,dop.file); 
                    dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);
                end
                if okay
                    % if point is wider than a single sample, there'll be heaps of points
                    % by subtracting point n from n+1, we'll get around this.
                    dop.tmp.ev_diff = diff(dop.tmp.ev) > 0;
                end
                if okay && ~sum(dop.tmp.ev_diff)
                    okay = 0;
                    msg{end+1} = sprintf(['No real events. Probably the case that' ...
                        ' the event signal was on at the start and was then' ...
                        ' reset by the program and then no markers were sent' ...
                        ' to this channel\n(%s: %s)'],mfilename,dop.file); 
                    dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);
                elseif okay 
                    % get the sample numbers
                    dop.event.samples = find(dop.tmp.ev_diff,sum(dop.tmp.ev_diff));
                end
            end
            if okay
                dop.event.n = numel(dop.event.samples);
                msg{end+1} = sprintf('\tFound %u events:',dop.event.n);
                dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);
                
                %% > separation
                dop.event.separation_samples = mean(diff(dop.event.samples));
                dop.event.separation_samples_stdev = std(diff(dop.event.samples));
                dop.event.separation_samples_min = min(diff(dop.event.samples));
                dop.event.separation_samples_max = max(diff(dop.event.samples));
                %% get the event times
                if ~isempty(dop.tmp.sample_rate)
                    dop.event.times_sec = dop.event.samples*(1/dop.tmp.sample_rate);
                    dop.event.times_ms = dop.event.times_sec*1000;
                    dop.event.times_min = dop.event.times_sec/60;
                    
                    dop.event.separation_secs = mean(diff(dop.event.samples*(1/dop.tmp.sample_rate)));
                    dop.use.event_sep = dop.event.separation_secs; % update for auto use in dopSetGetInputs
                    dop.event.separation_secs_stdev = std(diff(dop.event.samples*(1/dop.tmp.sample_rate)));
                    dop.event.separation_secs_min = min(diff(dop.event.samples*(1/dop.tmp.sample_rate)));
                    dop.event.separation_secs_max = max(diff(dop.event.samples*(1/dop.tmp.sample_rate)));
                    
                    %         dop.event.use_samples = dop.event.samples;
                    %         dop.event.downsamples = ones(dop.event.n,1)*-1; % make it negative when it's not available
                    %         if exist('downsample_rate','var') && ~isempty(downsample_rate) && ~isfield(dop.event,'downsamples')
                    %             dop.event.downsamples = round(dop.event.samples/...
                    %                 (sample_rate/downsample_rate));
                    %             dop.event.use_samples = dop.event.downsamples;
                    %         elseif ~isfield(dop.event,'downsamples')
                    %             fprintf('\t''dop.event.downsamples'' variable already exists, no correction required\n');
                    %             dop.event.downsamples = dop.event.sample;
                    %         end
                    
                    for i = 1 : dop.event.n
                        msg{end+1} = sprintf(['\t- %u:\t min = %3.2f, sec = %3.2f, ms = %.0f, ',...
                            '[sample = %u]'],...
                            i,dop.event.times_min(i),dop.event.times_sec(i),...
                            dop.event.times_ms(i),dop.event.samples(i));
                        dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);
                        %             fprintf(['\t- %u:\t min = %3.1f, sec = %3.1f, ms = %.0f, ',...
                        %                 '[sample = %u, down samples = %i]\n'],...
                        %                 i,dop.event.times_min(i),dop.event.times_sec(i),...
                        %                 dop.event.times_ms(i),dop.event.samples(i),...
                        %                 dop.event.downsamples(i));
                    end
                    % should draw in the separation variable and warn if
                    % there is potentially overlap
                    [dop,okay,msg] = dopPeriodChecks(dop,okay,msg);
                else
                    msg{end+1} = ['''dop.tmp.sample_rate'' variable not',...
                        'specified. Sample times in seconds haven''t been calculated'];
                    dopMessage(msg,dop.tmp.msg,1,okay,dop.tmp.wait_warn);
                end
            end
        end
        %         end
        dop.okay = okay;
        dop.msg = msg;
        dopOSCCIindent('done');%fprintf('\nRunning %s:\n',mfilename);
    end
catch err
    save(dopOSCCIdebug);rethrow(err);
end
end