function TMYTable = importTMYCSVfile(filename)
% Reconstructed compatibility loader for two supplied TMY CSV formats.
% The original project calculations in windTurbineAnalysis.m are unchanged.
% NSRDB Philadelphia: wind speed in column 14.
% NOAA station TMY: wind speed in column 11.
% Both have two metadata rows followed by a header row and 8760 data rows.
    filename = char(filename);
    fid = fopen(filename, 'r');
    if fid == -1
        error('Unable to open TMY file: %s', filename);
    end
    firstLine = fgetl(fid);
    fclose(fid);
    if startsWith(firstLine, 'Source,')
        windColumn = 14; % NSRDB
    elseif startsWith(firstLine, 'Location ID,')
        windColumn = 11; % NOAA TMY
    else
        error('Unrecognized TMY CSV format: %s', filename);
    end
    data = readmatrix(filename, 'NumHeaderLines', 3);
    if size(data, 2) < windColumn
        error('Wind speed column missing in %s', filename);
    end
    windSpeed = data(:, windColumn);
    if numel(windSpeed) ~= 8760 || any(~isfinite(windSpeed)) || any(windSpeed < 0)
        error('Expected 8760 valid nonnegative hourly wind speeds in %s', filename);
    end
    TMYTable = table(windSpeed, 'VariableNames', {'WindSpeed'});
end
