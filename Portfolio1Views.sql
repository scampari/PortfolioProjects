
select distinct continent
from Portfolio1..CovidDeaths
where isnull(continent, ' ') <> ' '

/*
select *
from Portfolio1..covidvaccinations
--where location like '%states%'
order by 3, 4 
*/

declare @Blank nvarchar(1)=''
SELECT nullif(continent,@Blank) 
FROM Portfolio1..CovidDeaths;

select location, date, total_cases, new_cases, total_deaths, population
from Portfolio1..CovidDeaths
order by 1, 2

--Death Rate from covid
select location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as DeathPercentage
from Portfolio1..CovidDeaths
where location like '%states%'
order by 1, 2

--Percentage of population that has gotten covid
select location, 
	date, 
	population, 
	total_cases, 
	(total_cases/population)*100 as PercentInfected
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
--where location like '%states%'
order by PercentInfected desc

--Countries with highest infection rate compared to population
select location,
	population, 
	MAX(total_cases) as HighestInfection, 
	MAX((total_cases/population))*100 as InfectionRate
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
Group by location, population
order by InfectionRate desc

--Countries with highest death rate
select location, 
	population, 
	MAX(total_deaths) as HighestMortality, 
	MAX((total_deaths/population))*100 as MortalityRate
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
Group by location, population
order by MortalityRate desc

Create View MortalitybyCountry
as
select location, 
	population, 
	MAX(total_deaths) as HighestMortality, 
	MAX((total_deaths/population))*100 as MortalityRate
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
Group by location, population


--Total Death by country
select location, 
	population, 
	MAX(total_deaths) as HighestDeaths 
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
Group by location, population
order by HighestDeaths desc

--VIEW Mortality Rate and Death Totals by country
Create View DeathsbyCountry
As
select location, 
	population, 
	MAX(total_deaths) as HighestDeaths 
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
Group by location, population

--Mortality rate by continent, kind of
select continent,
	MAX(total_deaths) as HighestMortality, 
	MAX((total_deaths/population))*100 as MortalityRateContinent
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
Group by continent
order by MortalityRateContinent desc

--View of Mortality rate by continent
Create View MortalityRateCont
As
select continent,
	MAX(total_deaths) as HighestMortality, 
	MAX((total_deaths/population))*100 as MortalityRateContinent
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
Group by continent


--Total deaths by continent
select continent,
	MAX(total_deaths) as TotalDeathCount 
from Portfolio1..CovidDeaths
where continent is not null and continent !=' '
Group by continent
order by TotalDeathCount desc

--Global Numbers per day
select
	date, 
	SUM(new_cases) as TotalCases,
	SUM(new_deaths) as TotalDeaths,
	SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
from Portfolio1..CovidDeaths
--where location like '%states%'
where continent is not null and continent !=' '
Group by date
order by 1, 2

--Global Death totals and percentages by date VIEW
Create View GlobalDeath
as select
	date, 
	SUM(new_cases) as TotalCases,
	SUM(new_deaths) as TotalDeaths,
	SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
from Portfolio1..CovidDeaths
--where location like '%states%'
where continent is not null and continent !=' '
Group by date



--Global cases and death percentage to date
select
	--date, 
	SUM(new_cases) as TotalCases,
	SUM(new_deaths) as TotalDeaths,
	SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
from Portfolio1..CovidDeaths
--where location like '%states%'
where continent is not null and continent !=' '
--Group by date
order by 1, 2

--Population VS Vax
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVac
From Portfolio1..CovidDeaths dea
join Portfolio1..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.continent !=' '
order by 2, 3

--This is a CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingVac)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVac
	--, (RollingVac/dea.population)*100
From Portfolio1..CovidDeaths dea
join Portfolio1..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.continent !=' '
)
Select *, (RollingVac/population)*100 as VaxPercent
From PopvsVac

--Creating View to store for visualisations

Create View PopVsVac as
With PopvsVac (continent, location, date, population, new_vaccinations, RollingVac)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVac
	--, (RollingVac/dea.population)*100
From Portfolio1..CovidDeaths dea
join Portfolio1..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.continent !=' '
)
Select *, (RollingVac/population)*100 as VaxPercent
From PopvsVac

-- This is a TEMP TABLE
/*
Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
RollingVax numeric
)

Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVax
	--, (RollingVac/dea.population)*100
From Portfolio1..CovidDeaths dea
join Portfolio1..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.continent !=' '

Select *, (RollingVax/population)*100 as VaxPercent
From #PercentPopulationVaccinated
*/

