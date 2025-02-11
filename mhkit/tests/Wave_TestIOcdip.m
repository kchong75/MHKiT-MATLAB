classdef Wave_TestIOcdip < matlab.unittest.TestCase
    %WAVE_TESTIOCDIP Testing CDIP data querying and formatting
    %   The Coastal Data Information Program (CDIP) measures, analyzes,
    %   archives and disseminates coastal environment data.
    %   https://cdip.ucsd.edu/
    
    methods (Test)

        function test_get_netcdf_variables_all2Dvars(testCase)
            vars2D = {'waveEnergyDensity', 'waveMeanDirection', ...
                      'waveA1Value', 'waveB1Value', 'waveA2Value', ...
                      'waveB2Value', 'waveCheckFactor', 'waveSpread', ...
                      'waveM2Value', 'waveN2Value'};

            data = cdip_request_parse_workflow( ...
                'station_number', '067', ...
                'years', 1996, ...
                'all_2D_variables', true);

            assertTrue(testCase, all(ismember(vars2D, fieldnames(data.data.wave2D))));
        end

        function test_get_netcdf_variables_params(testCase)
            parameters = {'waveHs', 'waveTp', 'notParam', 'waveMeanDirection'};

            data = cdip_request_parse_workflow( ...
                'station_number', '067', ...
                'years', 1996, ...
                'parameters', parameters);
            
            assertTrue(testCase, all(ismember({'waveHs', 'waveTp'}, ...
                fieldnames(data.data.wave))));
            assertTrue(testCase, all(ismember({'waveMeanDirection'}, ...
                fieldnames(data.data.wave2D))));
            assertTrue(testCase, all(ismember({'waveFrequency'}, ...
                fieldnames(data.metadata.wave))));
        end

        function test_get_netcdf_variables_time_slice(testCase)
            start_date = '1996-10-01';
            end_date = '1996-10-31';

            data = cdip_request_parse_workflow( ...
                'station_number', '067', ...
                'start_date', start_date, ...
                'end_date', end_date, ...
                'parameters', {'waveHs'});
            
            start_dt = datetime(start_date, ...
                'InputFormat', 'yyyy-MM-dd', ...
                'TimeZone', 'UTC');
            end_dt = datetime(end_date, ...
                'InputFormat', 'yyyy-MM-dd', ...
                'TimeZone', 'UTC');
            assertTrue(testCase, data.data.wave.waveTime(end) <= end_dt);
            assertTrue(testCase, data.data.wave.waveTime(1) >= start_dt);
        end

        function test_request_parse_workflow_multiyear(testCase)
            station_number = '067';
            year1 = 2011;
            year2 = 2013;
            years = [year1, year2];
            parameters = {'waveHs', 'waveMeanDirection', 'waveA1Value'};
            data = cdip_request_parse_workflow( ...
                'station_number', station_number, ...
                'years', years, ...
                'parameters', parameters);

            expected_index0 = datetime(year1, 1, 1, 'TimeZone', 'UTC');
            expected_index_final = datetime(year2, 12, 31, 'TimeZone', 'UTC');

            assertEqual(testCase, dateshift( ...
                data.data.wave.waveTime(1), 'start', 'day'), ...
                expected_index0);
            assertEqual(testCase, dateshift( ...
                data.data.wave.waveTime(end), 'start', 'day'), ...
                expected_index_final);
        end

        function test_request_parse_workflow_no_times(testCase)
            station_number = '100';
            data_type = 'historic';
            data = cdip_request_parse_workflow( ...
                'station_number', station_number, ...
                'data_type', data_type);

            assertEqual(testCase, data.data.wave.waveTime(1), ...
                datetime('30-Jan-2001 00:17:11', 'TimeZone', 'UTC'));
        end

        function test_plot_boxplot(testCase)
            data = cdip_request_parse_workflow( ...
                'station_number', '067', ...
                'years', 2011, ...
                'parameters', {'waveHs'}, ...
                'all_2D_variables', false);
            fig = plot_boxplot( ...
                data.data.wave.waveHs, ...
                data.data.wave.waveTime);

            filename = fullfile(tempdir, 'wave_plot_boxplot.png');
            saveas(fig, filename);
            assertTrue(testCase, isfile(filename));
            delete(filename);
        end

        function test_plot_compendium(testCase)
            data = cdip_request_parse_workflow( ...
                'station_number', '067', ...
                'years', 2011, ...
                'parameters', {'waveHs', 'waveTp', 'waveDp'}, ...
                'all_2D_variables', false);
            fig = plot_compendium( ...
                data.data.wave.waveHs, ...
                data.data.wave.waveTp, ...
                data.data.wave.waveDp, ...
                data.data.wave.waveTime);

            filename = fullfile(tempdir, 'wave_plot_compendium.png');
            saveas(fig, filename);
            assertTrue(testCase, isfile(filename));
            delete(filename);
        end

        function test_plot_compendium2(testCase)
            data = cdip_request_parse_workflow( ...
                'station_number', '067', ...
                'start_date', '2011-03-03', ...
                'end_date', '2011-03-31', ...
                'parameters', {'waveHs', 'waveTp', 'waveDp'}, ...
                'all_2D_variables', false);
            fig = plot_compendium( ...
                data.data.wave.waveHs, ...
                data.data.wave.waveTp, ...
                data.data.wave.waveDp, ...
                data.data.wave.waveTime);

            filename = fullfile(tempdir, 'wave_plot_compendium2.png');
            saveas(fig, filename);
            assertTrue(testCase, isfile(filename));
            delete(filename);
        end
    end
end

