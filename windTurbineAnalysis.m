
function windTurbineAnalysis()
    % Wind Turbine Performance and Economic Analysis
    % Analyzes TMY wind data across six cities and three turbine heights.
    % Calculates energy, operational hours, profitability, and breakeven.
    % Generates and exports engineering visualizations.

    close all;

    %% Initialize parameters
    heights = [100, 150, 200];
    bladeRadius = 75;
    cutInSpeed = 3.5;
    cutOutSpeed = 20;
    cp = 0.53;
    z0 = 0.6;
    lifetime = 25;
    electricityCost = 0.21;

    %% Load CSV datasets
    % Use the folder containing this MATLAB file.
    projectFolder = fileparts(mfilename('fullpath'));
    csvFiles = dir(fullfile(projectFolder, '*.csv'));

    if isempty(csvFiles)
        error('No CSV files found in the project folder.');
    end

    % Create folder for exported figures.
    resultsFolder = fullfile(projectFolder, 'results');

    if ~exist(resultsFolder, 'dir')
        mkdir(resultsFolder);
    end

    %% Initialize results structure
    results = struct( ...
        'cityName', {}, ...
        'height', {}, ...
        'monthlyEnergy', {}, ...
        'yearlyEnergy', {}, ...
        'operationalHours', {}, ...
        'breakevenYear', {}, ...
        'totalProfit', {}, ...
        'status', {}, ...
        'originalWindSpeed', {}, ...
        'adjustedWindSpeed', {}, ...
        'hourlyPower', {});

    %% Process each city and turbine height
    resultIndex = 1;

    for cityIdx = 1:length(csvFiles)

        filename = csvFiles(cityIdx).name;
        filePath = fullfile(projectFolder, filename);

        % Load hourly wind-speed observations.
        TMYTable = importTMYCSVfile(filePath);

        % Extract city name from filename.
        cityName = readUntilSecondUnderscore(filename);

        % Original wind speed at reference height.
        windSpeed10m = TMYTable.WindSpeed;

        for heightIdx = 1:length(heights)

            height = heights(heightIdx);

            % Adjust wind speed for turbine height.
            windSpeed = adjustWindSpeed( ...
                windSpeed10m, 10, height, z0);

            % Calculate hourly turbine power.
            [power, operationalHours] = calculateTurbinePower( ...
                windSpeed, bladeRadius, ...
                cutInSpeed, cutOutSpeed, cp);

            % Calculate monthly and yearly energy.
            [monthlyEnergy, yearlyEnergy] = ...
                calculateEnergyMetrics(power);

            % Perform financial analysis.
            [breakevenYear, totalProfit] = financialAnalysis( ...
                yearlyEnergy, electricityCost, ...
                height, bladeRadius, lifetime);

            % Assess installation viability.
            status = assessViability( ...
                monthlyEnergy, yearlyEnergy, ...
                operationalHours, breakevenYear, totalProfit);

            % Store calculated results.
            results(resultIndex).cityName = cityName;
            results(resultIndex).height = height;
            results(resultIndex).monthlyEnergy = monthlyEnergy;
            results(resultIndex).yearlyEnergy = yearlyEnergy;
            results(resultIndex).operationalHours = operationalHours;
            results(resultIndex).breakevenYear = breakevenYear;
            results(resultIndex).totalProfit = totalProfit;
            results(resultIndex).status = status;

            % Store hourly data for additional plots.
            results(resultIndex).originalWindSpeed = windSpeed10m;
            results(resultIndex).adjustedWindSpeed = windSpeed;
            results(resultIndex).hourlyPower = power;

            resultIndex = resultIndex + 1;
        end
    end

    %% Display results and generate plots
    displayResults(results);

    plotBreakevenAnalysis(results, heights, resultsFolder);

    plotAdditionalAnalysis( ...
        results, heights, electricityCost, ...
        lifetime, bladeRadius, resultsFolder);

    %% Extra Credit: Days with >12 operational hours
    calculateExtraCredit(results, csvFiles);

    fprintf('\nAnalysis completed successfully.\n');
    fprintf('Figures saved to:\n%s\n', resultsFolder);
end


%% Supporting Function 1: Adjust Wind Speed
function windSpeed = adjustWindSpeed( ...
    windSpeed, refHeight, targetHeight, z0)

    % Adjust wind speed using logarithmic wind profile.
    windSpeed = windSpeed .* ...
        (log(targetHeight/z0) / log(refHeight/z0));
end


%% Supporting Function 2: Calculate Turbine Power
function [power, operationalHours] = calculateTurbinePower( ...
    windSpeed, bladeRadius, cutInSpeed, cutOutSpeed, cp)

    % Standard air density in kg/m^3.
    rho = 1.225;

    % Initialize hourly power array.
    power = zeros(size(windSpeed));

    % Identify valid turbine operating hours.
    operationalMask = ...
        (windSpeed >= cutInSpeed) & ...
        (windSpeed <= cutOutSpeed);

    operationalHours = sum(operationalMask);

    % Calculate swept rotor area.
    sweptArea = pi * bladeRadius^2;

    % Calculate power in kW.
    power(operationalMask) = ...
        0.5 * cp * rho * sweptArea .* ...
        windSpeed(operationalMask).^3 / 1000;
end


%% Supporting Function 3: Calculate Energy Metrics
function [monthlyEnergy, yearlyEnergy] = ...
    calculateEnergyMetrics(power)

    % One-hour sampling interval.
    hourlyEnergy = power * 1;

    % Organize 8760 hours into 365 days.
    hourlyEnergy = reshape(hourlyEnergy, 24, 365);

    % Calculate energy for each day.
    dailyEnergy = sum(hourlyEnergy, 1);

    % Standard non-leap-year month lengths.
    monthDays = ...
        [31, 28, 31, 30, 31, 30, ...
         31, 31, 30, 31, 30, 31];

    monthlyEnergy = zeros(1, 12);

    startIdx = 1;

    for m = 1:12
        endIdx = startIdx + monthDays(m) - 1;

        monthlyEnergy(m) = ...
            sum(dailyEnergy(startIdx:endIdx));

        startIdx = endIdx + 1;
    end

    yearlyEnergy = sum(monthlyEnergy);
end


%% Supporting Function 4: Financial Analysis
function [breakevenYear, totalProfit] = financialAnalysis( ...
    yearlyEnergy, electricityCost, ...
    height, bladeRadius, lifetime)

    % Original simplified turbine cost model.
    baseCost = 1e6;
    heightCost = 5000 * height;
    bladeCost = 20000 * bladeRadius;

    installationCost = ...
        0.3 * (baseCost + heightCost + bladeCost);

    totalCost = ...
        baseCost + heightCost + ...
        bladeCost + installationCost;

    % Calculate annual electricity revenue.
    annualRevenue = yearlyEnergy * electricityCost;

    % Annual operation and maintenance cost.
    annualOM = 0.02 * totalCost;

    % Annual net cash flow.
    annualCashFlow = annualRevenue - annualOM;

    % Determine first year of breakeven.
    cumulativeCashFlow = 0;
    breakevenYear = lifetime + 1;

    for year = 1:lifetime

        cumulativeCashFlow = ...
            cumulativeCashFlow + annualCashFlow;

        if cumulativeCashFlow >= totalCost && ...
                breakevenYear > lifetime
            breakevenYear = year;
        end
    end

    % Calculate total profit after project lifetime.
    totalProfit = annualCashFlow * lifetime - totalCost;
end


%% Supporting Function 5: Installation Viability
function status = assessViability( ...
    monthlyEnergy, yearlyEnergy, operationalHours, ...
    breakevenYear, totalProfit)

    % Original installation criteria.
    minMonthlyEnergy = 500;
    minYearlyEnergy = 2e6;
    maxBreakeven = 2.5;
    minProfit = 10e6;
    minOperationalHours = 4380;

    avgMonthly = mean(monthlyEnergy);

    meetsMonthly = avgMonthly >= minMonthlyEnergy;
    meetsYearly = yearlyEnergy >= minYearlyEnergy;
    meetsHours = operationalHours >= minOperationalHours;
    meetsBreakeven = breakevenYear <= maxBreakeven;
    meetsProfit = totalProfit >= minProfit;

    if meetsMonthly && meetsYearly && ...
            meetsHours && meetsBreakeven && meetsProfit

        status = 'Ideal Installation';

    elseif meetsMonthly && meetsYearly && ...
            ~meetsBreakeven && meetsHours && meetsProfit

        status = ['Break Even Exceeds Maximum, ' ...
            'all other criteria met, city requires additional analysis'];

    elseif meetsMonthly && meetsYearly && ...
            ~meetsBreakeven && ~meetsHours

        status = ...
            'Turbine operation hours and required breakeven not met';

    elseif meetsMonthly && meetsYearly && ...
            ~(meetsHours || meetsBreakeven || meetsProfit)

        status = ...
            'Only total and monthly average energy production are met';

    else
        status = 'City does not meet installation requirements';
    end
end


%% Supporting Function 6: Display Results
function displayResults(results)

    fprintf('\n=== Wind Turbine Installation Viability Analysis ===\n\n');

    for i = 1:length(results)

        r = results(i);

        fprintf('City Name: %s\tTurbine Height: %dm\tStatus: %s\n', ...
            r.cityName, r.height, r.status);

        fprintf(' - Avg Monthly Energy: %.1f kWh\n', ...
            mean(r.monthlyEnergy));

        fprintf(' - Yearly Energy: %.1f kWh\n', ...
            r.yearlyEnergy);

        fprintf(' - Operational Hours: %d hours\n', ...
            r.operationalHours);

        fprintf(' - Breakeven Year: %.1f years\n', ...
            r.breakevenYear);

        fprintf(' - 25-year Profit: $%.2f million\n\n', ...
            r.totalProfit/1e6);
    end
end


%% Supporting Function 7: Breakeven Analysis Plot
function plotBreakevenAnalysis(results, heights, resultsFolder)

    % Identify cities and turbine heights.
    cityNames = unique(string({results.cityName}), 'stable');

    numCities = numel(cityNames);
    numHeights = numel(heights);

    breakevenData = zeros(numCities, numHeights);

    for c = 1:numCities
        for h = 1:numHeights

            idx = (c-1)*numHeights + h;

            breakevenData(c,h) = ...
                results(idx).breakevenYear;
        end
    end

    % Generate grouped bar chart.
    figure('Name', 'Wind Turbine Breakeven Analysis');

    bar(heights, breakevenData');

    xlabel('Turbine Height (m)');
    ylabel('Breakeven Year');

    title('Wind Turbine Breakeven Analysis by City and Height');

    legend(cityNames, ...
        'Location', 'bestoutside', ...
        'Interpreter', 'none');

    grid on;

    % Export chart for GitHub.
    exportgraphics(gcf, ...
        fullfile(resultsFolder, 'breakeven_analysis.png'), ...
        'Resolution', 150);
end


%% Supporting Function 8: Extra Credit
function calculateExtraCredit(results, csvFiles)

    fprintf('\n=== Extra Credit: Days with >12 Operational Hours ===\n\n');

    numCities = length(csvFiles);
    numHeights = 3;

    for cityIdx = 1:numCities

        cityName = readUntilSecondUnderscore( ...
            csvFiles(cityIdx).name);

        fprintf('City: %s\n', cityName);

        for heightIdx = 1:numHeights

            resultIdx = ...
                (cityIdx-1)*numHeights + heightIdx;

            r = results(resultIdx);

            % Original approximate calculation.
            % This is an estimate, not an exact daily count.
            daysOver12 = ...
                round(r.operationalHours / 24 * 0.6);

            fprintf( ...
                ' - Height %dm: %d days with >12 operational hours\n', ...
                r.height, daysOver12);
        end

        fprintf('\n');
    end
end


%% Supporting Function 9: Extract City Name
function cityName = readUntilSecondUnderscore(filename)

    % Extract city name from the CSV filename.
    parts = strsplit(char(filename), '_');

    if length(parts) >= 2
        cityName = strjoin(parts(1:2), '_');
    else
        cityName = char(filename);
    end

    cityName = strrep(cityName, '.csv', '');
end


%% Supporting Function 10: Additional Visualizations
function plotAdditionalAnalysis( ...
    results, heights, electricityCost, ...
    lifetime, bladeRadius, resultsFolder)

    cityNames = unique(string({results.cityName}), 'stable');

    numCities = numel(cityNames);
    numHeights = numel(heights);

    heightLabels = compose('%d m', heights);

    %% Figure 1: Power vs Original Wind Speed
    figure('Name', 'Power vs Original Wind Speed');

    tiledlayout(numCities, 1);

    for c = 1:numCities

        nexttile;
        hold on;

        for h = 1:numHeights

            idx = (c-1)*numHeights + h;

            scatter( ...
                results(idx).originalWindSpeed, ...
                results(idx).hourlyPower, ...
                3, 'filled');
        end

        xlabel('Original Wind Speed (m/s)');
        ylabel('Power (kW)');

        title(cityNames(c), 'Interpreter', 'none');

        legend(heightLabels, 'Location', 'best');

        grid on;
        hold off;
    end

    sgtitle('Hourly Turbine Power vs Original Wind Speed');

    exportgraphics(gcf, ...
        fullfile(resultsFolder, 'power_original_wind.png'), ...
        'Resolution', 150);


    %% Figure 2: Power vs Adjusted Wind Speed
    figure('Name', 'Power vs Adjusted Wind Speed');

    tiledlayout(numCities, 1);

    for c = 1:numCities

        nexttile;
        hold on;

        for h = 1:numHeights

            idx = (c-1)*numHeights + h;

            scatter( ...
                results(idx).adjustedWindSpeed, ...
                results(idx).hourlyPower, ...
                3, 'filled');
        end

        xlabel('Adjusted Wind Speed (m/s)');
        ylabel('Power (kW)');

        title(cityNames(c), 'Interpreter', 'none');

        legend(heightLabels, 'Location', 'best');

        grid on;
        hold off;
    end

    sgtitle('Hourly Turbine Power vs Adjusted Wind Speed');

    exportgraphics(gcf, ...
        fullfile(resultsFolder, 'power_adjusted_wind.png'), ...
        'Resolution', 150);


    %% Figure 3: Monthly Energy Production
    for c = 1:numCities

        monthlyData = zeros(12, numHeights);

        for h = 1:numHeights

            idx = (c-1)*numHeights + h;

            monthlyData(:,h) = ...
                results(idx).monthlyEnergy(:);
        end

        figure('Name', char(cityNames(c) + " Monthly Energy"));

        bar(1:12, monthlyData, 'grouped');

        xlabel('Month');
        ylabel('Energy Produced (kWh)');

        title("Monthly Energy Production - " + cityNames(c), ...
            'Interpreter', 'none');

        legend(heightLabels, 'Location', 'best');

        xticks(1:12);
        xticklabels({'Jan','Feb','Mar','Apr','May','Jun', ...
            'Jul','Aug','Sep','Oct','Nov','Dec'});

        grid on;

        exportgraphics(gcf, ...
            fullfile(resultsFolder, ...
            sprintf('monthly_energy_city_%d.png', c)), ...
            'Resolution', 150);
    end


    %% Figure 4: Profit Comparison
    profitData = zeros(numCities, numHeights);

    for c = 1:numCities
        for h = 1:numHeights

            idx = (c-1)*numHeights + h;

            profitData(c,h) = ...
                results(idx).totalProfit / 1e6;
        end
    end

    figure('Name', 'Turbine Profit Comparison');

    bar(profitData, 'grouped');

    xticks(1:numCities);
    xticklabels(cityNames);
    xtickangle(30);

    ylabel('25-Year Profit (Million USD)');
    title('Wind Turbine Profit Comparison');

    legend(heightLabels, 'Location', 'best');

    grid on;

    exportgraphics(gcf, ...
        fullfile(resultsFolder, 'profit_comparison.png'), ...
        'Resolution', 150);


    %% Figure 5: Cumulative Revenue and Cost
    years = 0:lifetime;

    for c = 1:numCities

        figure('Name', char(cityNames(c) + " Financial Analysis"));

        hold on;

        for h = 1:numHeights

            idx = (c-1)*numHeights + h;
            height = heights(h);

            % Preserve original cost assumptions.
            baseCost = 1e6;
            heightCost = 5000 * height;
            bladeCost = 20000 * bladeRadius;

            installationCost = ...
                0.3 * (baseCost + heightCost + bladeCost);

            totalCost = ...
                baseCost + heightCost + ...
                bladeCost + installationCost;

            % Calculate annual revenue.
            annualRevenue = ...
                results(idx).yearlyEnergy * electricityCost;

            % Annual operation and maintenance cost.
            annualOM = 0.02 * totalCost;

            % Calculate cumulative financial values.
            cumulativeRevenue = years * annualRevenue;
            cumulativeCost = totalCost + years * annualOM;

            % Revenue line.
            plot(years, cumulativeRevenue / 1e6, ...
                'LineWidth', 1.5, ...
                'DisplayName', sprintf('%d m Revenue', height));

            % Cost line.
            plot(years, cumulativeCost / 1e6, '--', ...
                'LineWidth', 1.5, ...
                'DisplayName', sprintf('%d m Cost', height));
        end

        xlabel('Year');
        ylabel('Cumulative Amount (Million USD)');

        title("Cumulative Revenue and Cost - " + cityNames(c), ...
            'Interpreter', 'none');

        legend('Location', 'best');

        grid on;
        hold off;

        exportgraphics(gcf, ...
            fullfile(resultsFolder, ...
            sprintf('financial_city_%d.png', c)), ...
            'Resolution', 150);
    end
end
