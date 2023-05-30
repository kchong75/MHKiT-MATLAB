function ds = read_nc_file(filename)
%%%%%%%%%%%%%%%%%%%%
%     Read NetCDF data structure.
%     
% Parameters
% ------------
%     filename: string
%         Filename of NetCDF file to read.
%
% Returns
% ---------
%     ds: structure 
%         Structure from the binary instrument data
%        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % check to see if the filename input is a string
    if ~ischar(filename)
        ME = MException('MATLAB:read_netcdf',['filename must be a ' ...
            'character string']);
        throw(ME);
    end
    
    % check to see if the file exists
    if ~isfile(filename)
        ME = MException('MATLAB:read_netcdf','file does not exist');
        throw(ME);
    end

    if isMATLABReleaseOlderThan("R2021b") || endsWith(filename, ".h5")
        ds = read_h5(filename);
        return
    end

    finfo = ncinfo(filename);
    %vnms = {finfo.Variables.Name}
    if ~isempty(finfo.Variables)
        vnms = {finfo.Variables.Name};
    else
        vnms = {};
    end
    % have groups? 
    if isempty(finfo.Groups)
        ginfo = finfo;
    else
        ginfo = finfo.Groups(1);
        vnms_temp = fullfile(ginfo.Name, ...
            {ginfo.Variables.Name});
        vnms = [vnms,strrep(vnms_temp,'\','/')];
    end
    % traverse through all groups and subgroups to get all variable names
    % as 'Group/subgroup/subsubgroups/.../varname'
    % BFS or DFS?
    %while ~isempty(ginfo)
        % vnms_temp = fullfile(f4info.Groups(1).Name,
        % {f4info.Groups(1).Variables.Name});
        % vnms = [vnms,strrep(vnms_temp,'\','/')];
    %end

    if isempty(vnms)
        ME = MException('MATLAB:read_nc_file',['no variable available' ...
            ' to read']);
        throw(ME);
    end
    %disp(vnms);
    ds = struct();
    
    for ivar=1:numel(vnms)
        name = vnms{ivar};
        %disp(name);
        % sz = ginfo.Variables(ivar).Size;
        % if length(sz)>1
        %     ds.(strrep(name,'/','_')).data = reshape(ncread(filename,name),sz);
        % else
        %     ds.(strrep(name,'/','_')).data = ncread(filename,name);
        % end
        ds.(strrep(name,'/','_')).data = ncread(filename,name);
        if ~isempty(ginfo.Variables(ivar).Dimensions)
            ds.(strrep(name,'/','_')).dims = ...
            {ginfo.Variables(ivar).Dimensions.Name};
        else
            ds.(strrep(name,'/','_')).dims = [];
        end
        ds.(strrep(name,'/','_')).FillValue = ginfo.Variables(ivar).FillValue;
        ds.(strrep(name,'/','_')).attrs = ginfo.Variables(ivar).Attributes;
    end
end
%res2 = read_nc_file('..\..\..\Sig500_Echo_inst2beam.nc'); 
% to-do: 1. catch invalid field name errors and convert symbols to
% _symbolnm: 'x*' to 'x_star'
% or:
%finfo = ncinfo(filename);
%xtemp = finfo.Variables;
%for ivar = 1:numel(xtemp)
%    xtemp(ivar).data = ncread(filename,xtemp(ivar).Name);
%end
% 2. BFS or DFS to loop through all variables
