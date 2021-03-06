function write_scan_images_to_disk(absolutePathForImageFiles,scanNum,viewType)

global planC stateS
indexS = planC{end};

%MySQL database (Development)
% conn = database('webCERR_development','root','xxxx','com.mysql.jdbc.Driver','jdbc:mysql://xxx/xxx_development');
conn = database('riview_dev','xxxx','xxxx','com.mysql.jdbc.Driver','jdbc:mysql://xxxx/xxx');

% Toggle plane locators
stateS.showPlaneLocators = 0;
CERRRefresh

% Set Dose Alpha value to 1
stateS.doseAlphaValue.trans = 0;
CERRRefresh

% Find this scan in database 
scanUID = planC{indexS.scan}(scanNum).scanUID;
sqlq_find_scan = ['Select id from scans where scan_uid = ''', scanUID,''''];
scan_raw = exec(conn, sqlq_find_scan);
scan = fetch(scan_raw);
scan = scan.Data;
if ~isstruct(scan)
    % skip if scan does not exist in database
    return;
else
    scan_id = scan.id;
end

% Create directory to store images
if ~exist(fullfile(absolutePathForImageFiles,['scan_',num2str(scan_id)],viewType),'dir')
    mkdir(fullfile(absolutePathForImageFiles,['scan_',num2str(scan_id)],viewType))
end

% Get coordinates
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));

%Show all HUs
CTOffset = planC{indexS.scan}(1).scanInfo(1).CTOffset;
minHU = min(planC{indexS.scan}.scanArray(:)) - CTOffset;
maxHU = max(planC{indexS.scan}.scanArray(:)) - CTOffset;
widthHU = (maxHU - minHU)/2;
centerHU = minHU + widthHU;
stateS.optS.CTWidth = widthHU*2;
stateS.optS.CTLevel = centerHU;

%Toggle dose off
stateS.doseToggle = -1;
stateS.doseSetChanged = 1;

%Toggle scan on
stateS.CTToggle = 1;
stateS.CTDisplayChanged = 1;

%setAxisInfo(stateS.handle.CERRAxis(1), 'scanSelectMode', 'manual', 'scanSets', scanNum, 'doseSelectMode', 'manual', 'doseSets', [] ,'doseSetsLast', [], 'view', viewType);
setAxisInfo(stateS.handle.CERRAxis(1), 'view', viewType, 'scanSelectMode', 'auto', 'doseSelectMode', 'auto', 'structSelectMode','auto');

%Set layout to display one large window
stateS.layout = 1;
sliceCallBack('resize',1)

%Toggle structures off
sliceCallBack('VIEWNOSTRUCTURES')

%Set scan to scanNum
sliceCallBack('SELECTSCAN',num2str(scanNum))

CERRRefresh

drawnow;


scanImageColNamesC = {'scan_id','file_location','view_type','coord'};

strContourColNamesC = {'structure_id','view_type','coord','segment_row_col'};

switch lower(viewType)
    
    case 'transverse'
        coordsV = zVals;
        
    case 'sagittal'
        coordsV = xVals;
        
    case 'coronal'
        coordsV = yVals;        
        
end


% Delete pointers to scan-images in database
scanUID = planC{indexS.scan}(scanNum).scanUID;
sqlq_delete_scan_images = ['Delete from scan_images where scan_id = ', num2str(scan_id), ' and view_type = ''', viewType(1),''''];
scan_images_delete = exec(conn, sqlq_delete_scan_images);

close(conn)

% scan_id
recC{1} = scan_id;
% view type
recC{3} = viewType(1);

for slcNum = 1:length(coordsV)
    %MySQL database (Development)
    % conn = database('webCERR_development','root','xxxx','com.mysql.jdbc.Driver','jdbc:mysql://xxx/xxx_development');
    conn = database('riview_dev','xxxx','xxxx','com.mysql.jdbc.Driver','jdbc:mysql://xxxx/xxx');
    
    setAxisInfo(stateS.handle.CERRAxis(1), 'coord', coordsV(slcNum));
    CERRRefresh
    drawnow;
    
    % Capture image
    F = getframe(stateS.handle.CERRAxis(1));
    imwrite(F.cdata, fullfile(absolutePathForImageFiles,['scan_',num2str(scan_id)],viewType,[viewType(1),num2str(coordsV(slcNum)),'.png']), 'png');
    
    %File location
    recC{2} = [viewType(1),num2str(coordsV(slcNum)),'.png'];
    %Coordinate
    recC{4} = coordsV(slcNum);
    
    insert(conn,'scan_images',scanImageColNamesC,recC);
    
    close(conn)
    
end




% Write structure contoures to database


%Toggle structures on
sliceCallBack('VIEWALLSTRUCTURES',num2str(scanNum))
recC = {};
recC{2} = viewType(1);

%MySQL database (Development)
% conn = database('webCERR_development','root','xxxx','com.mysql.jdbc.Driver','jdbc:mysql://xxx/xxx_development');
conn = database('riview_dev','xxxx','xxxx','com.mysql.jdbc.Driver','jdbc:mysql://xxxx/xxx');


% Delete structures from structure_contours table
% Delete existing contour segments for this slice
structureIndicesV = 1:length(planC{indexS.structures});
for structNum = structureIndicesV
    
    %Find structure_id in database for this structure
    sqlq_find_structure = ['Select id from structures where structure_uid = ''', planC{indexS.structures}(structNum).strUID, ''''];
    structure_raw = exec(conn, sqlq_find_structure);
    structure = fetch(structure_raw);
    structure = structure.Data;
    if ~isstruct(structure)
        % skip if scan does not exist in database
        continue;
    else
        structure_id = structure.id;
    end
    
    % Delete pointers to structure_contours from database
    sqlq_delete_structure_contours = ['Delete from structure_contours where structure_id = ', num2str(structure_id), ' and (view_type = ''', viewType(1),'''', ')'];
    structure_contours_delete = exec(conn, sqlq_delete_structure_contours);
    
end

for slcNum = 1:length(coordsV)
    
    setAxisInfo(stateS.handle.CERRAxis(1), 'coord', coordsV(slcNum));
    CERRRefresh
    
    recC{3} = coordsV(slcNum);
    
    % Find structures associated to this scan
    % numStructs = length(planC{indexS.structures});
    % assocScanV = getStructureAssociatedScan(1:numStructs);
    % structsInScanV = find(assocScanV == scanNum);
    
    % Get handles for all structures
    structureContours = findobj(stateS.handle.CERRAxis(1), 'tag', 'structContour');
    structureContoursC = get(structureContours,'userdata');
    if isempty(structureContoursC)
        continue;
    end
    if iscell(structureContoursC)
        structureContoursS = [structureContoursC{:}];
    else
        structureContoursS = structureContoursC;
    end
    structsInScanV = [structureContoursS.structNum];
    
    xLim = get(stateS.handle.CERRAxis(1),'xLim');
    yLim = get(stateS.handle.CERRAxis(1),'yLim');
    F = getframe(stateS.handle.CERRAxis(1));
    [nrows, ncols, jnk] = size(F.cdata);
    
    % Loop over structures to store contours in the database
    
%     %MySQL database (Development)
%     conn = database('webCERR_development','root','aa#9135','com.mysql.jdbc.Driver','jdbc:mysql://127.0.0.1/webCERR_development');
    
%     % Delete existing contour segments for this slice
%     for structNum = structsInScanV
%         
%         %Find structure_id in database for this structure
%         sqlq_find_structure = ['Select id from structures where structure_uid = ''', planC{indexS.structures}(structNum).strUID, ''''];
%         structure_raw = exec(conn, sqlq_find_structure);
%         structure = fetch(structure_raw);
%         structure = structure.Data;
%         if ~isstruct(structure)
%             % skip if scan does not exist in database
%             continue;
%         else
%             structure_id = structure.id;
%         end
%         
%         % Delete pointers to structure_contours from database
%         sqlq_delete_structure_contours = ['Delete from structure_contours where structure_id = ', num2str(structure_id), ' and (view_type = ''', viewType(1),'''', ' and coord = ', num2str(coordsV(slcNum)), ')'];
%         structure_contours_delete = exec(conn, sqlq_delete_structure_contours);
%         
%     end
    
    count = 0;
    for structNum = structsInScanV
        
        count = count + 1;
        
        %Find structure_id in database for this structure
        sqlq_find_structure = ['Select id from structures where structure_uid = ''', planC{indexS.structures}(structNum).strUID, ''''];
        structure_raw = exec(conn, sqlq_find_structure);
        structure = fetch(structure_raw);
        structure = structure.Data;
        if ~isstruct(structure)
            % skip if scan does not exist in database
            continue;
        else
            structure_id = structure.id;
        end
        
        recC{1} = structure_id;
        
        if strcmpi(viewType,'transverse')
            % Get x,y coordinates for this contour
            xData = get(structureContours(count),'xData');
            yData = get(structureContours(count),'yData');
            
            px = axes2pix(ncols,xLim,xData);
            py = axes2pix(nrows,yLim,yData);
            py = nrows - py;
            
            %     px = axes2pix(ncols,xLim,planC{indexS.structures}(12).contour(74).segments.points(:,1));
            %     py = axes2pix(nrows,-yLim,planC{indexS.structures}(12).contour(74).segments.points(:,2));
            
            
            ptsM = [px(:) py(:)];
            ptsRubyReadable = ptsM';
            ptsRubyReadable = ptsRubyReadable(:);
            ptsString = mat2str(ptsRubyReadable,6);
            ptsStringToWrite = ptsString(2:end-1);
            indSemiColV = strfind(ptsStringToWrite,';');
            ptsStringToWrite(indSemiColV) = ',';
            
            % Write this structure contour to db
            recC{4} = ptsStringToWrite;
            
            insert(conn,'structure_contours',strContourColNamesC,recC);
            
        else
            recC{1} = structure_id;
            countourMatrix = get(structureContours(count),'contourMatrix');
            current_contour = 1;
            cc = 1;
            totalPoints = length(countourMatrix(1,:));
            while current_contour < totalPoints
                
                numPoints = countourMatrix(2,current_contour);
                px = axes2pix(ncols,xLim,countourMatrix(1,current_contour+1:current_contour+numPoints));
                py = axes2pix(nrows,yLim,countourMatrix(2,current_contour+1:current_contour+numPoints));
                if strcmpi(viewType,'sagittal')
                    px = ncols - px;
                end
                current_contour = current_contour+numPoints+1;
                cc = cc+1;
                
                ptsM = [px(:) py(:)];
                ptsRubyReadable = ptsM';
                ptsRubyReadable = ptsRubyReadable(:);
                ptsString = mat2str(ptsRubyReadable,6);
                ptsStringToWrite = ptsString(2:end-1);
                indSemiColV = strfind(ptsStringToWrite,';');
                ptsStringToWrite(indSemiColV) = ',';
                
                % Write this structure contour to db
                recC{4} = ptsStringToWrite;
                
                insert(conn,'structure_contours',strContourColNamesC,recC);
                
            end
            
        end
        
    end
    
%     close(conn)
    
end


close(conn)



