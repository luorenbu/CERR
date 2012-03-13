function planC = guessPlanUID(planC,force,dcm)
% guessPlanUID
% This function creates linking UID's for the planC passed. Scan,
% dose and structures are given indipendent UID's and then the associated
% fields are updated.

%
% Usage:
%       planC = guessPlanUID(planC)
%
% See also CREATEUID.
%
% writter by : DK 13/07/06
%       LM: APA 08/17/06, Added UID links for IM structures
%           APA 10/11/06, Added code to update IM structure for old archives
%           WY  03/01/08, Add codes for generate associateScanUID when scan number more than 1;

% copyright (c) 2001-2008, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
indexS = planC{end};

if ~exist('oldPFlag')
    oldPFlag = 0;
end

nDoses = length(planC{indexS.dose});
nScans = length(planC{indexS.scan});
nStructures = length(planC{indexS.structures});

%
% wy add codes for generate associateScanUID when scan number more than 1;
% 
if exist('dcm', 'var') && (dcm)
    strAssocList = ones(1, nStructures);
    doseAssocList = ones(1, nDoses);
    for i = 1:nScans
        try
            scanUID = planC{indexS.scan}(i).scanUID;
        catch
            break;
        end
        for j = 1:nStructures
            assocScanUID = planC{indexS.structures}(j).assocScanUID;
            if strcmp(assocScanUID, scanUID)
                strAssocList(j) = i;
                continue;
            end
        end
        for j = 1:nDoses
            assocScanUID = planC{indexS.dose}(j).assocScanUID;
            if strcmp(assocScanUID, scanUID)
                doseAssocList(j) = i;
                continue;
            end
        end
    end
end

% 
%% Create Unique Identifier for Dose, Scan and Structures
%Extract information about scans.
% nScans = length(planC{indexS.scan});
for i = 1:nScans
    planC{indexS.scan}(i).scanUID = createUID('scan');
end

%Extract information about structures.
% nStructures = length(planC{indexS.structures});
for i = 1:nStructures
    planC{indexS.structures}(i).strUID = createUID('structure');
end

%Extract information about doses.
% nDoses = length(planC{indexS.dose});
for i = 1:nDoses
    planC{indexS.dose}(i).doseUID = createUID('dose');
end


nDVH = length(planC{indexS.DVH});

if nDVH == 1 & isempty(planC{indexS.DVH}.DVHMatrix)
    planC{indexS.DVH} = initializeCERR('DVH');

else
    for i = 1: nDVH
        planC{indexS.DVH}(i).dvhUID = createUID('DVH');
        % Link UID's in this loop for DVH

        % Link structure to DVH
        strName = planC{indexS.DVH}(i).structureName;
        structNum = getStructNum(strName,planC,indexS);
        if ~structNum
            CERRStatusString(['No Associated Structure for DVH ' strName ]);
            planC{indexS.DVH}(i).assocStrUID = '';
        else
            planC{indexS.DVH}(i).assocStrUID = planC{indexS.structures}(structNum).strUID;
        end

        % Link dose to DVH
        doseIndex = planC{indexS.DVH}(i).doseIndex;
        if isempty(doseIndex)
            CERRStatusString(['Dose Link cannot be guessed for DVH ' strName ]);
            planC{indexS.DVH}(i).assocDoseUID = '';
        else
            try
                planC{indexS.DVH}(i).assocDoseUID = planC{indexS.dose}(doseIndex).doseUID;
            catch
                planC{indexS.DVH}(i).assocDoseUID = [];
            end
        end
    end
end

% check for IVH fields
nIVH = length(planC{indexS.IVH});
for i = 1:nIVH
    % Link structure to IVH
    strName = planC{indexS.IVH}(i).structureName;
    structNum = getStructNum(strName,planC,indexS);
    if ~structNum
        CERRStatusString(['No Associated Structure for Intensity Volume Histogram' strName ]);
        planC{indexS.IVH}(i).assocStrUID = '';
    else
        planC{indexS.IVH}(i).assocStrUID = planC{indexS.structures}(structNum).strUID;
    end

    % Link scan to IVH
    scanIndex = planC{indexS.IVH}(i).scanIndex;
    if isempty(scanIndex)
        CERRStatusString(['Scan Link cannot be guessed for ' strName ]);
        planC{indexS.IVH}(i).assocScanUID = '';
    else
        planC{indexS.IVH}(i).assocScanUID = planC{indexS.scan}(scanIndex).scanUID;
    end
end

%% check for IM fileds
nIM = length(planC{indexS.IM});
for i = 1:nIM
    % Copy beams, goals, solution, params fields from IMsetup to IMDosimetry
    if ~isfield(planC{indexS.IM}(i),'IMDosimetry') && isfield(planC{indexS.IM}(i),'IMSetup')
        planC{indexS.IM}(i).IMDosimetry = planC{indexS.IM}(i).IMSetup;
    else
        %do nothing asuming IMDosimerty was properly populated
    end

    % check for empty dosimetry and assign default name
    if ~isempty(planC{indexS.IM}(i).IMDosimetry)
        % Assign a default name 'IM doseSet'
        planC{indexS.IM}(i).IMDosimetry.name = 'IM doseSet';
        % Assume Dosimetry (beamlets) is fresh (1=fresh, 2=stale)
        planC{indexS.IM}(i).IMDosimetry.isFresh = 1;
    end
    
    % Link structure UID to goals
    if isfield(planC{indexS.IM}(i).IMDosimetry,'goals')
        for j = 1:length(planC{indexS.IM}(i).IMDosimetry.goals)
            structNum = planC{indexS.IM}(i).IMDosimetry.goals(j).structNum;
            planC{indexS.IM}(i).IMDosimetry.goals(j).strUID = planC{indexS.structures}(structNum).strUID;
        end        

        % Link scan UID to IM
        planC{indexS.IM}(i).IMDosimetry.assocScanUID = planC{indexS.scan}(1).scanUID;

        % put beamlets under its parent beam        
        structPresentV = ~cellfun('isempty',squeeze({planC{indexS.IM}(i).IMDosimetry.beamlets.beamNum}));
        structPresentM = reshape(structPresentV,size(planC{indexS.IM}(i).IMDosimetry.beamlets));
        beamletTotal = 0;
        for beamNum = 1:length(planC{indexS.IM}(i).IMDosimetry.beams)
            numBeamlets = length(planC{indexS.IM}(i).IMDosimetry.beams(beamNum).xPBPosV);            
            planC{indexS.IM}(i).IMDosimetry.beams(beamNum).beamlets = planC{indexS.IM}(i).IMDosimetry.beamlets(structPresentM(:,1),beamletTotal+1:beamletTotal+numBeamlets);
            beamletTotal = beamletTotal + numBeamlets;
        end

        % assign strUID
        count = 0;
        strPresentV = find(structPresentM(:,1));
        for strNum = 1:length(strPresentV)
            count = count + 1;
            for beamNum = 1:length(planC{indexS.IM}(i).IMDosimetry.beams)
                [planC{indexS.IM}(i).IMDosimetry.beams(beamNum).beamlets(count,:).strUID] = deal(planC{indexS.structures}(strPresentV(strNum)).strUID);
            end
        end

        % remove beamlets field from IMDosimetry since it is a part of beams now
        planC{indexS.IM}(i).IMDosimetry = rmfield(planC{indexS.IM}(i).IMDosimetry,'beamlets');
        
        %rename solution to solutions
        if isfield(planC{indexS.IM}(i).IMDosimetry,'solution')
            planC{indexS.IM}(i).IMDosimetry.solutions =  planC{indexS.IM}(i).IMDosimetry.solution;
            planC{indexS.IM}(i).IMDosimetry = rmfield(planC{indexS.IM}(i).IMDosimetry,'solution');
        end

    end
end

% remove IMSetup field
if isfield(indexS,'IM') && isfield(planC{indexS.IM},'IMSetup')
    planC{indexS.IM} = rmfield(planC{indexS.IM},'IMSetup');
end

%% Link Structures and dose to Scan
if nScans == 1 && exist('force','var') && force
    scanUID = planC{indexS.scan}.scanUID;

    % Link dose set
    if nDoses == 0
        planC{indexS.dose} = initializeCERR('dose');
    else
        for i = 1:nDoses
            planC{indexS.dose}(i).assocScanUID =  scanUID;
        end
    end
    % Link structure set
    if nStructures == 0 | (nStructures == 1 & isempty(planC{indexS.structures}.contour) )
        nStructures = 0;
        planC{indexS.structures} = initializeCERR('structures');
    end

    for i = 1:nStructures
        planC{indexS.structures}(i).assocScanUID =  scanUID;
    end

    % Link structureArray

    % check for the bug with older plans where structure set length is 1
    % although the fields are empty
    if length(planC{indexS.structureArray}) == 1 & isempty(planC{indexS.structureArray}.bitsArray)
        planC{indexS.structureArray} = initializeCERR('structureArray');
        planC{indexS.scan}(1).uniformScanInfo = [];
    end


    if length(planC{indexS.structureArray})>1, errordlg('Invalid Structure Set Encountered'); end;

    planC{indexS.structureArray}(1).assocScanUID =  scanUID;

    planC{indexS.structureArray}(1).structureSetUID =  createUID('structureSet');
    
elseif nScans > 1 && exist('force','var') && force
    
%     wy rewrite the codes for Linking dose and structures to multiple
%     scans.
    if exist('dcm', 'var') && (dcm)
        for i = 1:nDoses
            planC{indexS.dose}(i).assocScanUID =  planC{indexS.scan}(doseAssocList(i)).scanUID;
        end

        for i = 1:nStructures
            if ~isempty(planC{indexS.scan})
                planC{indexS.structures}(i).assocScanUID =  planC{indexS.scan}(strAssocList(i)).scanUID;
            end
        end
        return;
    end

    assocScanIndx = getStructureAssociatedScan(1:nStructures,planC);
    %CERRStatusString('Using depricated "getStructureAssociatedScan" function for linking structures');

    for i = 1:length(unique(assocScanIndx))
        strSet = find(assocScanIndx == i);
        try
            scanUID = planC{indexS.scan}(i).scanUID;
        catch
            scanUID = createUID('scan');
        end
        for j = 1:length(strSet)
            planC{indexS.structures}(strSet(j)).assocScanUID = scanUID;
        end %j
        % Also link the structure Array in this area
        planC{indexS.structureArray}(i).assocScanUID =  scanUID;

        planC{indexS.structureArray}(i).structureSetUID =  createUID('structureSet');
    end %i
    
%     for i = 1:nDoses
%         if i == 1
%             str1 = {'Trying to load previously merged Plans.'};
%             str2 = {''};
%             str3 = {'Due to linking bug in older version associatedScanUID field for doses will be left empty'};
%             warnStr = horzcat(str1,str2,str3);
%             hWarnMerge = warndlg(warnStr);
%             waitfor(hWarnMerge);
%         end
%         planC{indexS.dose}(i).assocScanUID = '';
%     end
end

%% Linking Dose to Scan
