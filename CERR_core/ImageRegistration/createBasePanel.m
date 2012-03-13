function createBasePanel(handles)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.


global planC stateS;
indexS = planC{end};
    
    %create a tree view and initialize filter parameters;
    w = 0.3; h = 0.6;
    createTreeView(handles, w, h);
    handles = guidata(handles.mainframe);
    
    fsize = 9;
    
    %create output list panel
    handles.outputPanel = uipanel('Parent',handles.mainframe,'Units','characters','FontSize',fsize,'Title','Output','Tag','OutputPanel',...
                    'Clipping','on','Units','normalized','Position',[0 0 w 1-h]);

    handles.OutputList = uicontrol('Parent',handles.outputPanel,'Units','normalized',...
                    'FontSize',fsize,'Position',[0 0 1 1],'Style','listbox', 'Tag','OutputList');
        
    %add generalPanel,toolPanel and optionPanel
    w = 0.3; h1 = 0.30; h2 = 0.6; h3 = 1-h1-h2;
    handles.generalPanel = uipanel('parent', handles.mainframe, 'units', 'normalize', 'FontSize',fsize, 'position', [w h2+h3 1-w h1]);
    
    handles.toolPanel = uipanel('parent', handles.mainframe, 'FontSize',fsize, 'units', 'normalize', 'position', [w h3 1-w h2]);
    
    handles.optionPanel = uipanel('parent', handles.mainframe, 'FontSize',fsize, 'Title','Options', 'units', 'normalize', ...
                                  'position', [w 0 1-w h3]);

    %do button
    handles.doButton = uicontrol(handles.optionPanel, 'style', 'pushbutton', 'units', 'pixel', ...
                            'position', [310 10 100 28], 'string', 'Continue', ...
                            'tag', 'continueButton', 'callback', 'CERRRegistrationRigidSetup(''auto_registration'')');

% Options                        
    %downsample option
    dy = 20;
    handles.dsampleCheck = uicontrol(handles.optionPanel, 'style', 'checkbox', 'units', 'pixel', 'value', 0, ...
                                'position', [2 24 136 20], 'string', 'downSample(2x2x2)', 'tag', 'dsamplecheckbox');
    handles.saveCheck = uicontrol(handles.optionPanel, 'style', 'checkbox', 'units', 'pixel', 'Value', 0, ...
                                'position', [2 2 136 20], 'string', 'save resampled data', 'tag', 'savecheckbox');
    
    InitTranstext = uicontrol(handles.optionPanel, 'style', 'text', 'units', 'pixel', ...
                                'position', [138 1 50 16], 'string', 'InitTrans:');
    handles.InitTrans = uicontrol(handles.optionPanel, 'style', 'popup', 'units', 'pixel', 'value', 1, ...
                                'position', [188 4 86 18], 'string', 'MomentsOn|GeometryOn|InitTransMOn','tag', 'InitTrans');
%     
    handles.flipX = uicontrol(handles.optionPanel, 'style', 'checkbox', 'units', 'pixel', 'Value', 0, ...
                                'position', [138 24 50 20], 'string', 'flipX', 'tag', 'flipX', 'enable', 'off');
    handles.flipY = uicontrol(handles.optionPanel, 'style', 'checkbox', 'units', 'pixel', 'Value', 0, ...
                                'position', [188 24 50 20], 'string', 'flipY', 'tag', 'flipY', 'enable', 'off');
    handles.flipZ = uicontrol(handles.optionPanel, 'style', 'checkbox', 'units', 'pixel', 'Value', 0, ...
                                'position', [238 24 50 20], 'string', 'flipZ', 'tag', 'flipZ', 'enable', 'off');
    
        
 
%     2D Match
%     handles.match2DCheck = uicontrol(handles.optionPanel, 'style', 'checkbox', 'units', 'pixel', 'Value', 0, ...
%                                 'position', [138 15 80 28], 'string', '2D
%                                 Match', 'tag', 'match2Dcheckbox');

%registration method panel
    handles.registrationMethodPanel = uipanel('Parent',handles.generalPanel,'Units','normalize', 'FontSize',fsize,...
                                'Title','Image Registration Method','Tag','regMethodPanel','Clipping','off',...
                                'Position',[0 0 1 1], 'Visible','on');

                            
    dy = -1; dx = -5;
    h21 = uicontrol(...
    'Parent',handles.registrationMethodPanel,...
    'Units','characters',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Position',[6+dx 10.2307692307692+dy 20.6 2],...
    'String','Transform:',...
    'Style','text',...
    'Tag','text6');

    handles.transform = uicontrol(...
    'Parent',handles.registrationMethodPanel,...
    'Units','characters',...
    'FontSize',10,...
    'Position',[28.2+dx 10.1538461538462+dy 51 2.07692307692308],...
    'String',{ 'Similarity Transform'; 'Versor3D Transform'; 'Euler Transform';  },... %'Affine Transform'
    'Style','popupmenu',...
    'CallBack', 'createParaPanel(guidata(gcbf), ''transform_advance'')', ...
    'Value',1);
    
%     try
%         [x, map] = imread('help-book-open.gif', 'GIF');
%         a = ind2rgb(x, map);
%     catch
%         a = [];
%     end
%     handles.helpButton = uicontrol(handles.registrationMethodPanel, 'style', 'pushbutton', 'units', 'characters', ...
%                             'cdata', a, 'position', [80+dx 10.1538461538462+dy 6 2.07692307692308], 'string', '', ...
%                             'tag', 'continueButton', 'callback', 'winopen(''irqat.chm'')');

    h23 = uicontrol(...
    'Parent',handles.registrationMethodPanel,...
    'Units','characters',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Position',[6+dx 7.38461538461539+dy 20.6 2],...
    'String','Interpolator:',...
    'Style','text',...
    'Tag','text7');

    handles.interpolater = uicontrol(...
    'Parent',handles.registrationMethodPanel,...
    'Units','characters',...
    'FontSize',10,...
    'Position',[28.2+dx 7.30769230769231+dy 51 2.07692307692308],...
    'String',{  'Linear Interpolate'; 'Nearest Interpolate'},...
    'Style','popupmenu',...
    'Value',1);

    h25 = uicontrol(...
    'Parent',handles.registrationMethodPanel,...
    'Units','characters',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Position',[6+dx 4.61538461538462+dy 20.6 2],...
    'String','Similarity Metric:',...
    'Style','text',...
    'Tag','text8');

    handles.metric = uicontrol(...
    'Parent',handles.registrationMethodPanel,...
    'Units','characters',...
    'FontSize',10,...
    'Position',[28.2+dx 4.53846153846154+dy 51 2.07692307692308],...
    'String',{  'Mean Squares'; 'Normalized Correlation' },...
    'Style','popupmenu',...
    'Value',1);

    h27 = uicontrol(...
    'Parent',handles.registrationMethodPanel,...
    'Units','characters',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Position',[6+dx 1.92307692307692+dy 20.6 2],...
    'String','Optimizer:',...
    'Style','text',...
    'Tag','text9');

    handles.optimizer = uicontrol(...
    'Parent',handles.registrationMethodPanel,...
    'Units','characters',...
    'FontSize',10,...
    'Position',[28.2+dx 1.84615384615385+dy 51 2.07692307692308],...
    'String','RegularStepGradientDescent',...
    'Style','popupmenu',...
    'Value',1);
                       
    %save handles
    guidata(handles.mainframe, handles);                
end                    


