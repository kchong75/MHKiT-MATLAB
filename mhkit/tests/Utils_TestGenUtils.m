classdef Utils_TestGenUtils < matlab.unittest.TestCase

    methods (Test) 



        function test_get_statistics(testCase)
            relative_file_name = '../../examples/data/loads/loads_data_dict.json'; % filename in JSON extension
            full_file_name = fullfile(fileparts(mfilename('fullpath')), relative_file_name);
            fid = fopen(full_file_name); % Opening the file
            raw = fread(fid,inf); % Reading the contents
            str = char(raw'); % Transformation
            fclose(fid); % Closing the file
            data = jsondecode(str); % Using the jsondecode function to parse JSON from string
            
            freq = 50; % Hz
            period = 600; % seconds
            vector_channels = {"WD_Nacelle","WD_NacelleMod"};
            
            % load in file
            loads_data_table = struct2table(data.loads);
            df = table2struct(loads_data_table,'ToScalar',true);
            
            df.Timestamp = datetime(df.Timestamp);
            df.time = df.Timestamp;
            % run function
            stats = get_statistics(df,freq,"period",period,"vector_channels",vector_channels);
            % check statistics
            assertEqual(testCase,stats.mean.uWind_80m,7.773,'AbsTol',0.01); % mean
            assertEqual(testCase,stats.max.uWind_80m,13.271,'AbsTol',0.01); % max
            assertEqual(testCase,stats.min.uWind_80m,3.221,'AbsTol',0.01); % min
            assertEqual(testCase,stats.std.uWind_80m,1.551,'AbsTol',0.01); % standard deviation3
            assertEqual(testCase,stats.std.WD_Nacelle,36.093,'AbsTol',0.01); % std vector averaging
            assertEqual(testCase,stats.mean.WD_Nacelle,178.1796,'AbsTol',0.01);% mean vector averaging
        end      

        function test_excel_to_datetime(testCase)
            % store excel timestamp
            excel_time = 42795.49212962963;
            % corresponding datetime
            time = datetime(2017,03,01,11,48,40);
            % test function
            answer = excel_to_datetime(excel_time);

            % check if answer is correct
            assertEqual(testCase,answer,time);
        end

        function test_magnitude_phase(testCase)
            % 2-d function
            magnitude = 9;
            y = sqrt(1/2*magnitude^2); x=y;
            phase = atan2(y,x);
            [mag, theta] = magnitude_phase({x; y});
            assert(all(magnitude == mag))
            assert(all(phase == theta))
            xx = [x,x]; yy = [y,y];
            [mag, theta] = magnitude_phase({xx; yy});
            assert(all(magnitude == mag))
            assert(all(phase == theta))
            % 3-d function
            magnitude = 9;
            y = sqrt(1/3*magnitude^2); x=y; z=y;
            phase1 = atan2(y,x);
            phase2 = atan2(sqrt(x.^2 + y.^2),z);
            [mag, theta, phi] = magnitude_phase({x; y; z});
            assert(all(magnitude == mag))
            assert(all(phase1 == theta))
            assert(all(phase2 == phi))
            xx = [x,x]; yy = [y,y]; zz = [z,z];
            [mag, theta, phi] = magnitude_phase({xx; yy; zz});
            assert(all(magnitude == mag))
            assert(all(phase1 == theta))
            assert(all(phase2 == phi))
        end
        function test_read_nc_file_group(testCase)
            % Check MATLAB version
            if isMATLABReleaseOlderThan("R2021b")
                return;
            end
            fnms = {dir('example_ncfiles/').name};
            %1. Check LongName with group path
            %fprintf("1. Check LongName with group path: ");
            fnm = 'QA4ECV_L2_NO2_OMI_20180301T052400_o72477_fitB_v1.nc';
            res = read_nc_file_group(strcat('example_ncfiles/',fnm));
            val1 = res.groups.PRODUCT.groups.SUPPORT_DATA.groups.INPUT_DATA.LongName;
            val2 = '/PRODUCT/SUPPORT_DATA/INPUT_DATA';
            assertEqual(testCase,val1,val2);
            %2. Check Group Attributes
            %fprintf("2. Check Group Attributes: ");
            finfo = ncinfo(strcat('example_ncfiles/',fnm));
            val1 = res.groups.METADATA.groups.ALGORITHM_SETTINGS.groups.SLANT_COLUMN_RETRIEVAL.Attributes;
            val2 = finfo.Groups(2).Groups(1).Groups(1).Attributes;
            assertEqual(testCase,val1,val2);
            %3. Check Variables
            %fprintf("3. Check Variable \n");
            % file with groups
            %fprintf("Check file with groups\n");
            % '/PRODUCT/SUPPORT_DATA/DETAILED_RESULTS'
            ginfo = finfo.Groups(1).Groups(1).Groups(2);
            vnms = {ginfo.Variables.Name};
            sz = size(ginfo.Variables);
            % 3.1 check Dims
            %fprintf("3.1 Check Variable Dims: ");
            idx = randi([1,sz(2)],1); 
            vname = check_name(vnms{idx});
            val1 = res.groups.PRODUCT.groups.(['SUPPORT_' ...
                'DATA']).groups.DETAILED_RESULTS.Variables.(vname).Dims;
            val2 = {ginfo.Variables(idx).Dimensions.Name};
            val3 = size(res.groups.PRODUCT.groups.(['SUPPORT_' ...
                'DATA']).groups.DETAILED_RESULTS.Variables.(vname).Data);
            val4 = size(ncread(strcat('example_ncfiles/',fnm),...
                strcat('PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/',vnms{idx})));
            assertEqual(testCase,val1,val2);
            assertEqual(testCase,val3,val4);
            % 3.2 check Data
            %fprintf("3.2 Check Variable Data: ");
            idx = randi([1,sz(2)],1); 
            vname = check_name(vnms{idx});
            val1 = res.groups.PRODUCT.groups.(['SUPPORT_' ...
                'DATA']).groups.DETAILED_RESULTS.Variables.(vname).Data;
            val2 = ncread(strcat('example_ncfiles/',fnm),...
                strcat('PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/',vnms{idx}));
            
            testCase.verifyTrue(isequaln(val1,val2),vname);
            % 3.3 check Attributes
            %fprintf("3.3 Check Variable Attributes: \n");
            idx = randi([1,sz(2)],1); 
            vname = check_name(vnms{idx});
            in_names = {ginfo.Variables(idx).Attributes.Name};
            in_vals = {ginfo.Variables(idx).Attributes.Value};
            xtemp = res.groups.PRODUCT.groups.(['SUPPORT_' ...
                'DATA']).groups.DETAILED_RESULTS.Variables;
            for iattr = 1:numel(in_names)
                %fprintf(" - Attr %s: ",in_names{iattr});
                if strcmp(in_names{iattr},'_FillValue')
                    out_val = xtemp.(vname).FillValue;
                else
                    out_val = xtemp.(vname).Attrs.(in_names{iattr});
                end
                testCase.verifyTrue(isequaln(in_vals{iattr},out_val));
            end

            % file without groups
            %fprintf("Check file without groups\n");
            for ifnm = 3:numel(fnms)
                fnm = fnms{ifnm};
                if strcmp(fnm,'QA4ECV_L2_NO2_OMI_20180301T052400_o72477_fitB_v1.nc')
                    continue
                end
                fprintf("Checking File: %s \n",fnm);
                res = read_nc_file_group(strcat('example_ncfiles/',fnm));
                ginfo = ncinfo(strcat('example_ncfiles/',fnm));
                vnms = {ginfo.Variables.Name};
                sz = size(ginfo.Variables);
                % 3.1 check Dims
                %fprintf("3.1 Check Variable Dims: ");
                idx = randi([1,sz(2)],1); 
                count = 0;
                while (isempty(ginfo.Variables(idx).Dimensions)&&count<10)
                    idx = randi([1,sz(2)],1); 
                    count = count + 1;
                end
                if ~isempty(ginfo.Variables(idx).Dimensions)
                    vname = check_name(vnms{idx});
                    val1 = res.Variables.(vname).Dims;
                    val2 = {ginfo.Variables(idx).Dimensions.Name};
                    val3 = size(res.Variables.(vname).Data);
                    val4 = size(ncread(strcat('example_ncfiles/',fnm),vnms{idx}));
                    assertEqual(testCase,val1,val2);
                    assertEqual(testCase,val3,val4);
                end
                % 3.2 check Data
                %fprintf("3.2 Check Variable Data: ");
                idx = randi([1,sz(2)],1); 
                vname = check_name(vnms{idx});
                count = 0;
                while (isempty(ginfo.Variables(idx).Dimensions)&&count<10)
                    idx = randi([1,sz(2)],1); 
                    count = count + 1;
                end
                val1 = res.Variables.(vname).Data;
                val2 = ncread(strcat('example_ncfiles/',fnm),vnms{idx});
                %testCase.verifyTrue(isequaln(val1,val2),{vname,val1,val2});
                testCase.verifyTrue(isequaln(val1,val2),vname);
                % 3.3 check Attributes
                %fprintf("3.3 Check Variable Attributes: \n");
                idx = randi([1,sz(2)],1); 
                count = 0;
                while (isempty(ginfo.Variables(idx).Attributes)&&count<10)
                    idx = randi([1,sz(2)],1); 
                    count = count + 1;
                end
                vname = check_name(vnms{idx});
                if ~isempty(ginfo.Variables(idx).Attributes)
                    in_names = {ginfo.Variables(idx).Attributes.Name};
                    in_vals = {ginfo.Variables(idx).Attributes.Value};
                    for iattr = 1:numel(in_names)
                        %fprintf(" - Attr %s: ",in_names{iattr});
                        if strcmp(in_names{iattr},'_FillValue')
                            out_val = res.Variables.(vname).FillValue;
                        else
                            out_val = res.Variables.(vname).Attrs.(in_names{iattr});
                        end
                        testCase.verifyTrue(isequaln(in_vals{iattr},out_val));
                    end
                end
            
            end
        end
    end
end  




        