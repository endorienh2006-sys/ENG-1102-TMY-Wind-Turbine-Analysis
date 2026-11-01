# Wind Turbine Performance and Economic Analysis

MATLAB coursework project comparing wind turbine output, annual operating hours, profitability and breakeven periods at **100 m, 150 m and 200 m** for six US cities.

## Contents

- `windTurbineAnalysis.m` — main project analysis recovered from the original submitted PDF. The calculations and original approximate extra-credit formula are preserved.
- `importTMYCSVfile.m` — reconstructed CSV import helper supporting both NOAA station TMY and NSRDB TMY formats.
- `*_TMY_1998-2022.csv` — five NOAA station-based Typical Meteorological Year datasets.
- `PA_Philadelphia_tmy-2022-1.csv` — the recovered Philadelphia NSRDB CSV.
- `Project_Report.pdf` — archived original MATLAB project output, results and plot.

## Run

1. Download or clone this repository, and open MATLAB.
2. Set MATLAB's **Current Folder** to the directory containing these files.
3. In the Command Window run `windTurbineAnalysis`.
4. The script reads the six `*.csv` files, prints results and generates a breakeven plot.

The CSVs must stay in the same working directory as the `.m` files. The importer detects the CSV format by its metadata header and reads the correct wind-speed column.

## Model assumptions

Blade radius 75 m; cut-in speed 3.5 m/s; cut-out speed 20 m/s; power coefficient 0.53; surface roughness length 0.6 m; project lifetime 25 years; electricity price $0.21/kWh. The analysis uses a simplified turbine cost model and assumes each CSV contains 8760 hourly wind-speed observations.

## Data and reconstruction notes

The Philadelphia data is an NSRDB export recovered from the project materials. The five other city datasets were obtained later from NOAA station-based TMY exports (1998–2022). Their numerical results **may differ** from the original archived report; that report reflects the historical coursework submission and is not a validation of these replacement datasets.

The MATLAB main program was reconstructed from the original PDF, and the data import function was recreated because its original source was unavailable. The original source's extra-credit days-over-12-hours calculation is explicitly an **approximation**, not an exact daily count. The source has not been executed in MATLAB in this environment.

## Source data station IDs

| City | Station ID / source |
| --- | --- |
| Wichita, KS | USW00003923 |
| Springfield, MO | USW00013995 |
| Albuquerque, NM | USW00023050 |
| New York City, NY | USW00094728 (Central Park) |
| Salt Lake City, UT | USW00024127 (International Airport) |
| Philadelphia, PA | NSRDB Location ID 1207856 |

Data source: NOAA National Centers for Environmental Information TMY station downloads, and the supplied Philadelphia NSRDB export.
