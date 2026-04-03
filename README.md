📊 COVID-19 Analytics Project (SQL)

🔹 Overview

SQL project analyzing global COVID-19 data to track cases, deaths, and vaccinations and generate insights for reporting and dashboards.

🔹 Data Sources
CovidDeaths: cases, deaths, population
CovidVaccinations: daily vaccination data

Database: PortfolioProject

🔹 Key Analysis
Death Rate → total_deaths / total_cases
Infection Rate → total_cases / population
Continent Impact → total deaths by region
Global Metrics → total cases, deaths, % death rate
Vaccination Progress → rolling vaccinated population
🔹 Techniques Used
Joins
Window Functions (SUM OVER)
CTE (Common Table Expressions)
Temporary Tables
Views
Data Cleaning (NULLIF, TRY_CAST)
🔹 Output
Rolling vaccination metrics
% population vaccinated
Country & continent-level insights

Final View:

dbo.PercentPopulationVaccinatedFinal

🔹 Use Case
Data analysis
Dashboard integration (Power BI)
KPI tracking
🔹 Key Value

Transforms raw COVID data into actionable insights ready for visualization and decision-making.
