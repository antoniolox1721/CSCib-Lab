function ret= view_io(op, a1, a2)
% Save "ScopeData" to a .mat file: view_io save
% To load a selected .mat file   : view_io load
% Plot the data in "ScopeData"   : view_io plot

% Sept 2023, J. Gaspar

if nargin<1
    op= 'gui'; %'cnf_gui'; %-1; %1; %0;
end

switch op
    case 'gui'
        % default
        view_io_gui
    case {'acq', 'acquire'}
        % usage: view_io acquire
        open_sim_and_run()

    case {-1, 'show', 'plot'}
        % default (not the default anymore...)
        % usage: view_io plot
        show_data_in_workspace
    case {0, 'save'}
        % usage: view_io save
        save_data_to_mat_file
    case {1, 'load'}
        % usage: view_io load
        if nargin>1
            % accept filename as an argument
            load_data_from_mat_file(a1);
        else
            % use a dialog to get the filename
            load_data_from_mat_file
        end
    case {2, 'load_and_show'}
        % usage: view_io load_and_show
        load_data_from_mat_file
        show_data_in_workspace
        
    case {'getSignals', 'get', 'get2'}
        % usage: view_io get
        if ~is_data_in_workspace
            error('failed getting ScopeData')
        end
        if ismember(op, {'getSignals', 'get'})
            % simply return signals exactly as in the workspace
            ret= evalin('base', 'ScopeData');
        else
            % 'get2', return signals parsed by options
            ret= get_and_parse_data;
        end

    case 'cnf'
        % configure view_io
        % usage e.g.: view_io('cnf', 'SelectSignals', 1:4)
		%  [1:4] means [time ref pot strain]
		%  [1 4] means [time strain]
        view_io_cnf('set', a1, a2);
    case 'cnf_show'
        % usage: view_io cnf_show
        view_io_cnf('show');
     case 'cnf_clear'
        % usage: view_io cnf_clear
        view_io_cnf('clear');
    case 'cnf_gui'
        % usage: view_io cnf_gui
        view_io_cnf_gui();
       
    case 'anim'
        % usage: view_io anim
        anim_arm('view_io_data');
        
    otherwise
        fprintf(1, 'ERR: op= '); disp(op)
        error('inv op')
end


function view_io_gui
strList= {
    'Load ScopeDat from a mat file to the workspace', 'load_data_from_mat_file';
    'Save ScopeData from the workspace to a mat file', 'save_data_to_mat_file';
    'Define the content of ScopeData', 'view_io_cnf_gui';
    'Plot the ScopeData existing in the workspace', 'show_data_in_workspace';
    'Run animation from ScopeData', 'anim_arm("view_io_data");'
    'Open Simulink and move the real flexible bar', 'open_sim_and_run';
    };
for i= 1:size(strList,1)
    strList{i,2}= strrep(strList{i,2}, '"', '''');
end

[indList, okFlag] = listdlg('PromptString',...
    {'Select all the desired operations', '(press Cancel to do nothing):'},...
    'SelectionMode','multiple', ... %'single',...
    'ListSize', [300 100], ...
    'ListString', strList(:,1) );
if ~okFlag
    return
end

for i= indList
    eval( strList{i,2} );
end

return


% ---------------------------------------------------------------------
function open_sim_and_run
NIBoardModel= niboard('get');
mname= ['view_record_' NIBoardModel];
fname= [mname '.mdl'];

str= {'Confirm apply signal to rotate the flexbar?'; ...
    'Important: check sensor and actuation cables are plugged.'};
str= questdlg(str, 'move confirm', 'Yes','No','No');
if strcmp(str, 'No')
    return;
end

open(fname);
set_param(mname, 'SimulationCommand', 'start')


% ---------------------------------------------------------------------
function ret= view_io_cnf( op, a1, a2 )
% usages:
% view_io( 'cnf_show' )
global VIO
switch op
    case 'set', VIO.(a1)=a2;
    case 'get', ret= VIO.(a1);
    case 'show', disp(VIO)
    case 'clear', VIO=[];

    case 'istrue'
        if ~isfield( VIO, a1 ) || isempty(VIO.(a1))
            ret= 0;
        elseif isnumeric(VIO.(a1)) && numel(VIO.(a1))==1 && ~VIO.(a1)
            ret= 0;
        else
            ret= 1;
        end

    otherwise
        error('inv op')
end


function view_io_cnf_gui()
% usage: view_io cnf_gui

global VIO

prompt0= {
    'Workspace var name', def_or_opt('ScopeData',VIO,'wsScopeDataName');
    'Time is in the array of values (0,1)', def_or_opt('1',VIO,'timeExistsInValues');
    'Select signals in [time,ref,pot,strain] (1:4)', def_or_opt('1:4',VIO,'SelectSignals');
    'Signals [time,ref,pot,strain] in deg (e.g. [] or 2:4)', def_or_opt('[]',VIO,'SignalsInDeg');
    'Plot this data (0,1)', '1';
    'Clear this config (0,1)', '0';
    };

defaultans = prompt0(:,2);
prompt= prompt0(:,1);
dlg_title = 'Input';
num_lines = 1; % [1 50] gives 50chrs width

answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
if isempty(answer)
    return
end

if eval(answer{end})
    % just clear all, and return
    view_io_cnf( 'clear' ); return
end

% parse all options, and save them in the global variable
if ~strcmp(answer{1}, 'ScopeData') || isfield(VIO, 'wsScopeDataName')
    if isempty(answer{1}), return; end
    VIO.wsScopeDataName= answer{1};
end
if ~isempty(answer{2})
    VIO.timeExistsInValues= eval(answer{2});
end
if ~isempty(answer{3})
    VIO.SelectSignals= eval(answer{3});
end
if ~isempty(answer{4}) || (isempty(answer{4}) && ~isempty(VIO.SignalsInDeg))
    VIO.SignalsInDeg= eval(answer{4});
end

% finally plot the data
if eval(answer{4})
    show_data_in_workspace
end
return


function ret= def_or_opt( defaultValue, options, fieldname )
%
% Return a default value or a value specified via options.
% Options may not contain the fieldname (i.e. no value)
% When options have the fieldname (and value) it has precedence
%
% Usage example:
% abc= def_or_opt( 123, options, 'abc');

% 2022 JG

if isfield( options, fieldname )
    ret= getfield( options, fieldname );
else
    ret= defaultValue;
end

if ischar(defaultValue) && isnumeric(ret)
    if numel(ret)==1
        ret= num2str(ret);
    else
        ret= ['[' num2str(ret) ']'];
    end
end


% ---------------------------------------------------------------------
function ret= is_data_in_workspace
ret= 1;
str0= 'exist(''ScopeData'', ''var'')';
if ~evalin('base', str0)

    % ask to download, or quit
    str= {'No data in the workspace to show.', ' Load data from file?'};
    str= questdlg(str, 'load data?', 'Yes','No','No');
    if ~strcmp(str, 'Yes')
        % quit
        ret= 0;
        return
    end
    
    % put ScopeData in the workspace
    load_data_from_mat_file
    if ~evalin('base', str0)
        ret= 0; % failed ...
    end
end


function ret= get_and_parse_data
% ret: Nx4 : array [time ref pot strainGauge]

% by default get data from the workspace variable "ScopeData"
wsScopeDataName= 'ScopeData';
if view_io_cnf('istrue', 'wsScopeDataName')
    % view_io('cnf', 'wsScopeDataName', 'myvar')
    wsScopeDataName= view_io_cnf('get', 'wsScopeDataName');
end
ScopeData= evalin('base', wsScopeDataName);

% enforce ret to be one NxM array
if ~isstruct(ScopeData)
    % 1. ScopeData is an array with time
    ret= ScopeData;
elseif view_io_cnf('istrue', 'timeExistsInValues') && ...
        view_io_cnf('get', 'timeExistsInValues')
    % 2. ScopeData is a struct with time
    % time is a column in the array "values"
    % view_io('cnf', 'timeExistsInValues', 1)
    ret= ScopeData.signals.values;
else
    % 3. ScopeData is a struct with time
    % time has to be added to the array "values"
    % view_io('cnf', 'timeExistsInValues', 0)
    ret= [ScopeData.time ScopeData.signals.values];
end

% enforce ret to have just the desired columns
ret= select_signals( ret );

% enforce radians instead of degrees
ret= conv_deg_to_rad( ret );

return


function ScopeData= select_signals( ScopeData )
if view_io_cnf('istrue', 'SelectSignals')
    % view_io('cnf', 'SelectSignals', 1:4)
    ind= view_io_cnf('get', 'SelectSignals');
    ind(ind>size(ScopeData,2))= size(ScopeData,2);
    ScopeData= ScopeData(:,ind);
end


function ScopeData= conv_deg_to_rad( ScopeData )
if view_io_cnf('istrue', 'SignalsInDeg')
    ind= view_io_cnf('get', 'SignalsInDeg');
    ScopeData(:,ind)= ScopeData(:,ind)*pi/180;
end


% ---------------------------------------------------------------------
function show_data_in_workspace
if ~is_data_in_workspace
    return
end

ScopeData= get_and_parse_data;
leg= {'ref'};
for i= 3:size(ScopeData,2)
    leg{end+1}= sprintf('input %d', i-2);
end
ini= 2;
if view_io_cnf('istrue', 'SkipRef')
    leg(1)= [];
    ini= 3;
end

if ~view_io_cnf('istrue', 'UseCurrentFig')
    figure(201); clf
end

plot(ScopeData(:,1), ScopeData(:,ini:end), '.-');
xlabel('time [sec]');
legend(leg)
if view_io_cnf('istrue', 'TitleAsFilename')
    fname= view_io_cnf('get', 'TitleAsFilename');
    title( strrep(fname,'_','\_') );
end


function save_data_to_mat_file
pcname= getenv('COMPUTERNAME');
ScopeData= evalin('base', 'ScopeData');
fname= mkfname(['ScopeData_' pcname '_'], 'mat', struct('outputFormat',2) );
save( fname, 'pcname', 'ScopeData' )


function load_data_from_mat_file( pfname )
if nargin<1
    [fname, pname]= uigetfile('*.mat');
    pfname= [pname fname];
end
load(pfname, 'ScopeData');
if exist('ScopeData', 'var')
    assignin('base', 'ScopeData', ScopeData);
else
    fprintf(1, '** bad file: %s\n', pfname);
end
return


function fname= mkfname( basePath, extension, options )
%
% function fname= mkfname( basePath, extension, options )
%
% Create a filename based on the current date.
%
% The base name has the form yymmddtn (yy = year, mm = month,
%  dd = day, t = character t, n = number >=1) and is
%  prefixed with basePath and sufixed with
%  ['.' extension]
%
% If the generated file name already exists,
%   then mkfname increments n to generate a new filename
%
% Usage examples:
%   fname= mkfname
%   fname= mkfname( 'path/' )
%   fname= mkfname( 'path/', 'jpg')
%   fname= mkfname( 'prefix', 'jpg')
%   fname= mkfname( 'path/', 'jpg', struct('outputFormat',2) )
%   fname= mkfname( 'path/', 'jpg', struct('outputFormat',3) )
%   fname= mkfname( 'fname.mat', '', struct('baseHasExt',1) )
%
% Results of the usage examples (date= 18-Jun-2004, time= 01:23:45):
%   '040618t1', 'path/040618t1', 'path/040618t1.jpg', 'path/040618_012345.jpg'

% The first implementation was:
%
% The base name has the form yymmddab (yy = year, mm = month,
%  dd = day, a = f(hour), b = f(minute)) and is
%  prefixed with basePath and sufixed with
%  ['.' extension]
% e.g. '990701ua' (u codify the hour and a codify the minute)
%

% 12/8/99, 18/6/04 (doc++), 2020.09.03 (options), J. Gaspar

if nargin<1,
    basePath= [];
end
if nargin<2,
    extension= [];
end
if nargin<3
    options= [];
end

outputFormat= 1;
if isfield(options, 'outputFormat')
    outputFormat= options.outputFormat;
end
if isfield(options, 'baseHasExt') && options.baseHasExt
    [p, f, extension]= fileparts( basePath );
    basePath= strrep(basePath, extension, '');
end

if ~isempty(extension) && isempty(find(extension=='.', 1))
    extension= ['.' extension];
end

% make the filename using the current time
[y,m,d,h,mi,s]= datevec(now); n=1;

while 1,
    switch outputFormat
        case 1
            % original idea makes wrong ordering
            %str= sprintf('%02d%02d%02d%c%c', ...
            %    rem(y,100), m, d, char(97+h), codeMi(mi));
            
            % yymmddt1, yymmddt2, ...
            str= sprintf('%02d%02d%02dt%d', ...
                rem(y,100), m, d, n);
            
        case {2, 3}
            % yymmdd_hhmmss, yymmdd_hhmmss(1), ...
            if outputFormat==2
                str= sprintf('%02d%02d%02d_%02d%02d%02d', ...
                    rem(y,100), m, d, h, mi, round(s));
            else
                % do not include secs: yymmdd_hhmm, yymmdd_hhmm(1), ...
                str= sprintf('%02d%02d%02d_%02d%02d', ...
                    rem(y,100), m, d, h, mi);
            end
            if n>1
                str= [str '(' num2str(n-1) ')'];
            end
            
        otherwise
            error('invalid outputFormat');
    end
    
    fname= [basePath str extension];
    if ~exist(fname,'file'),
        break;
    else
        % mi= mi+1; % old idea
        n= n+1;
    end
end


% ----- aux function
% function chr= codeMi(mi)
% % mi is in 0..59
% % chr is in abbccdd..zz001122334
% mi= round(mi/2);
% if mi>25,
%    chr= num2str(mi-26);
% else
%    chr= char(97+mi);
% end
