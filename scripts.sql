/********************************************************************
-- Project: Covid Analytics
-- Author: [Your Name]
-- Purpose: Analyze Covid-19 data: Cases, Deaths, Population, Vaccinations
-- Database: PortfolioProject
-- Notes: This project calculates infection and vaccination metrics,
--        including cumulative totals and percentages for dashboards.
********************************************************************/

-- ==========================
-- 1. Base Queries - Raw Data
-- ==========================
/*
Definition: 
These queries extract the raw CovidDeaths (cases, deaths, population) and 
CovidVaccinations tables for inspection. Useful to understand the structure 
and preview the data before performing analytics.
*/
SELECT TOP 10 *
FROM PortfolioProject..CovidDeaths
ORDER BY date, location;

SELECT TOP 10 *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY date, location;

-- Preview focused columns
SELECT location, date, total_cases, total_deaths, new_cases, population
FROM PortfolioProject..CovidDeaths;


-- ==========================
-- 2. Basic Analytics
-- ==========================
/*
Definition: 
Compute essential metrics at the country level:
- Death rate (total_deaths / total_cases)
- Percent of population infected
- Highest infection counts per country
These help identify countries with severe outbreaks.
*/

-- Total cases vs total deaths for a specific country
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths * 100.0 / NULLIF(total_cases, 0)) AS death_rate_percent
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Tunisia%';

-- Total cases vs population (percentage infected)
SELECT 
    location,
    date,
    total_cases,
    population,
    (total_cases * 100.0 / NULLIF(population, 0)) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
  AND location LIKE '%Tunisia%';

-- Highest infection rates by country
SELECT
    location,
    population,
    HighestInfectionCount,
    (HighestInfectionCount * 100.0 / population) AS PercentPopulationInfected
FROM (
    SELECT location, population, MAX(total_cases) AS HighestInfectionCount
    FROM PortfolioProject..CovidDeaths
    WHERE total_cases IS NOT NULL
      AND continent IS NOT NULL
    GROUP BY location, population
) t
ORDER BY PercentPopulationInfected DESC;


-- ==========================
-- 3. Continent-Level Analytics
-- ==========================
/*
Definition: 
Aggregate metrics by continent to identify regions most affected.
- Maximum deaths per continent
- Global new cases and death rate
Useful for regional comparisons and global trends.
*/

-- Maximum deaths per continent
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathsCount DESC;

-- Global numbers: new cases, deaths, death rate
SELECT
    SUM(TRY_CAST(new_cases AS int)) AS total_new_cases,
    SUM(TRY_CAST(new_deaths AS int)) AS total_new_deaths,
    (SUM(TRY_CAST(new_deaths AS int)) * 100.0 / NULLIF(SUM(TRY_CAST(new_cases AS int)), 0)) AS DeathsPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;


-- ==========================
-- 4. Population vs Vaccinations
-- ==========================
/*
Definition:
Compare population to vaccinations:
- Rolling total of vaccinated people by country
- Provides cumulative vaccination progress
- Useful for dashboard visualization
*/

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.continent, dea.location, dea.date;


-- ==========================
-- 5. Using CTE (Common Table Expression)
-- ==========================
/*
Definition:
CTEs are temporary result sets useful for intermediate calculations.
Here, PopVsVac calculates rolling vaccinations per country and
the percentage of population vaccinated. This structure improves readability 
and maintainability.
*/

WITH PopVsVac AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated * 100.0 / population) AS PercentPopulationVaccinated
FROM PopVsVac;


-- ==========================
-- 6. Temporary Table Example
-- ==========================
/*
Definition:
Temporary tables store intermediate results for complex calculations.
They are session-specific and automatically dropped after the session ends.
Here, it stores rolling vaccination totals and population percentages.
*/

CREATE TABLE #PercentPopulationVaccinated (
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    NewVaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- Calculate percentage of population vaccinated
SELECT *,
       (RollingPeopleVaccinated * 100.0 / Population) AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;


-- ==========================
-- 7. View for Dashboard / Power BI
-- ==========================
/*
Definition:
Create a persistent view to store rolling vaccination metrics and percentages.
This view can be used directly in dashboards, reports, or Power BI for visualization.
It avoids recalculating rolling totals every time and centralizes the logic.
*/

CREATE OR ALTER VIEW dbo.PercentPopulationVaccinatedFinal AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated,
    (SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) * 100.0 / dea.population) AS PercentPopulationVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Preview the view
SELECT TOP 10 *
FROM dbo.PercentPopulationVaccinatedFinal;
