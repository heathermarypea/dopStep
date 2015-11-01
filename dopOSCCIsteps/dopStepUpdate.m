function dop = dopStepUpdate(dop)
% dopOSCCI3: dopStepUpdate
%
% notes:
% update the information in the gui figure based on dopStepSettings
%
% Use:
%
% dopStepUpdate;
%
% where:
%
% Created: 15-Oct-2015 NAB
% Edits:
% 

try
    fprintf('\nRunning %s:\n',mfilename);
    %% get the figure handle
    if ~exist('dop','var') || isempty(dop)
        dop = get(gcf,'UserData');
        if isempty(dop) || ~isstruct(dop) || ~isfield(dop,'step') || ~isfield(dop.step,'h')
            error('Can''t find ''dopStep'' figure');
        end
    end
    %% clear current contents
    if isfield(dop.step,'current') && isfield(dop.step.current,'h')
        %         n = dop.step.current;
        for i = 1 : numel(dop.step.current.h)
            delete(dop.step.current.h(i));
        end
        %             switch n.style{i}
        %                 case 'text'
        %                     dop.step.current.h(i) = uicontrol(dop.step.h,...
        %                         'style',n.style{i},'String',n.string{i},...
        %                         'tag',n.tag{i},...
        %                         'Units','Normalized',...
        %                         'Position',n.position(i,:));
        %                 otherwise
        %                     warndlg(sprintf('Style (%s), not recognised - can''t create',n.style{i}));
        %             end
        %         end
        drawnow;
    end
    %% create next contents
    if isfield(dop.step,'next')
        % update the current settings
        dop.step.previous = dop.step.current;
        dop.step.current = dop.step.next;
        if isfield(dop.step.current,'h')
            dop.step.current = rmfield(dop.step.current,'h');
        end
        n = dop.step.current;
        dop.step.text.h = []; % clear text handles
        for i = 1 : numel(n.style)
            switch n.style{i}
                case {'text','edit','pushbutton'}
                    % generic
                    dop.step.current.h(i) = uicontrol(dop.step.h,...
                        'style',n.style{i},'String',n.string{i},...
                        'tag',n.tag{i},...
                        'Units','Normalized',...
                        'Position',n.position(i,:),...
                        'HorizontalAlignment',n.HorizontalAlignment{i});
                    % specific
                    switch n.style{i}
                        case 'text'
                            set(dop.step.current.h(i),'BackgroundColor',...
                                get(dop.step.h,'Color'));
                        case {'edit','pushbutton'}
                            set(dop.step.current.h(i),'CallBack',dop.step.next.Callback{i},...
                                'Enable',n.Enable{i});
                    end
                    if isfield(dop.step.next,'Visible')
                        set(dop.step.current.h(i),'Visible',dop.step.next.Visible{i});
                    end
                    dop.step.text.h(i) = dop.step.current.h(i);
                otherwise
                    warndlg(sprintf('Style (%s), not recognised - can''t create',n.style{i}));
            end
        end
        
        % set gui data
        if sum(ismember(dop.step.current.tag,'data_file')) && isfield(dop,'fullfile') && exist(dop.fullfile,'file')
            dop.tmp.h = dop.step.current.h(ismember(dop.step.current.tag,'data_file'));
            set(dop.tmp.h,'string',dop.fullfile);
        end
        for i = 1 : numel(dop.step.action.tag)
            
            dop.tmp.h = dop.step.action.h(ismember(dop.step.action.tag,dop.step.action.tag{i}));
            set(dop.tmp.h,'enable','off');
            switch dop.step.action.tag{i}
                case 'import'
                    % should the import button be on?
                    % if there's a data_file to import
                    if isfield(dop,'fullfile') && exist(dop.fullfile,'file')
                        set(dop.tmp.h,'enable','on');
                        if sum(ismember(dop.step.current.tag,'import_text'))
                            set(dop.step.current.h(ismember(dop.step.current.tag,'import_text')),'Visible','On')
                        end
                    end
                case 'plot'
                    % should the plot button be on?
                    % if there's 'use' data to plot
                    if isfield(dop,'data') && isfield(dop.data,'use') && ~isempty(dop.data.use)
                        set(dop.tmp.h,'enable','on');
                        if sum(ismember(dop.step.current.tag,'plot_text'))
                            set(dop.step.current.h(ismember(dop.step.current.tag,'plot_text')),'Visible','On')
                        end
                    end
            end
        end
                    
%         for i = 1 : numel(dop.step.action.h)
%             switch get(dop.step.action.h(i),'tag')
%                 case 'import'
%                     
%                 case 'plot'
%             end
%         end
        
    end
    
    %% update UserData
    set(dop.step.h,'UserData',dop);
    % welcome/instruction
%     dop = dopStepWelcome(dop);
    
catch err
    save(dopOSCCIdebug);rethrow(err);
end
end