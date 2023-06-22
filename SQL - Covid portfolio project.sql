/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


--Selecting data to be used

Select Location, date, total_cases, new_cases, total_deaths, population
From SQLProject..CovidDeaths
Order by 1,2


--Comparing Total Cases vs Total Deaths; likelihood of dying from COVID per country

Select Location, date, total_cases, total_deaths, (cast(total_deaths as decimal)/cast(total_cases as decimal))*100 as DeathPercentage
From SQLProject..CovidDeaths
Order by 1,2


--Comparing Total cases vs population; what percentage was infected per country

Select Location, date, population, total_cases, (total_cases/population)*100 as InfectedPercentage
From SQLProject..CovidDeaths
Order by 1,2
 

--Countries with highest Infection Rate per population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From SQLProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From SQLProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- Contintents with the highest death count per population

Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From SQLProject..CovidDeaths
Where continent is null AND Location NOT LIKE '%income'
Group by location
order by TotalDeathCount desc


-- Total global cases

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From SQLProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingVaccinatedCount
--, (RollingVaccinatedCount/population)*100
From SQLProject..CovidDeaths dea
Join SQLProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopVsVac (continent, location, date, population, new_vaccinations, RollingVaccinatedCount)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingVaccinatedCount
From SQLProject..CovidDeaths dea
Join SQLProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingVaccinatedCount/Population)*100 as TotalVaxPercent
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinatedCount numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingVaccinatedCount
From SQLProject..CovidDeaths dea
Join SQLProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingVaccinatedCount/Population)*100 as TotalVaxPercent
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingVaccinatedCount
--, (RollingVaccinatedCount/population)*100
From SQLProject..CovidDeaths dea
Join SQLProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


Select*
From PercentPopulationVaccinated