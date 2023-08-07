select * from portfolioProject..covid_death$ order by 3,4

--select * from portfolioProject..covidVaccination order by 3,4

--select data we are going to be use

select Location,date,total_cases,new_cases,total_deaths,population 
from portfolioProject..covid_death$ order by 1,2

--looking at total cases vs new cases
-- shows likelihood of dying if you contract covid  in your country

select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as deathPercentage
from portfolioProject..covid_death$ 
order by 1,2

--Looking at total cases vs population
--shows what percentage of population got covid

select Location,date,population,total_cases,(total_cases/population)*100 as deathPercentage
from portfolioProject..covid_death$ 
order by 1,2

-- countries with highest infection rates

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From portfolioProject..covid_death$
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--countries with highest death count per population 

select Location, max(cast(Total_deaths as int)) as TotalDeathCount
from portfolioProject..covid_death$
where continent is not null
group by Location
order by TotalDeathCount desc

-- lets break things by continent
select Location, max(cast(Total_deaths as int)) as TotalDeathCount
from portfolioProject..covid_death$
where continent is null
group by Location
order by TotalDeathCount desc

--showing continent with highest death count per population
select continent, max(cast(Total_deaths as int)) as TotalDeathCount
from portfolioProject..covid_death$
where continent is not null
group by continent
order by TotalDeathCount desc

--Global Numbers 
SET ANSI_WARNINGS OFF
select date,sum(new_cases) as total_cases, sum(nullif(new_deaths,0))as total_death,
sum(nullif(new_deaths,0)) /sum(nullif(New_Cases,0))*100 as DeathPercentage from portfolioProject..covid_death$
where continent is not null
group by date
order by 1,2

--Total in one line ---

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From portfolioProject..Covid_death$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- total population vs vaccination
select dea.continent, dea.date,dea.population,vac.new_vaccinations ,
sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.location,dea,date) as people vaccinated
from portfolioProject..covid_death$ dea join portfolioProject..covidVaccination vac 
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigInt,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From portfolioProject..covid_death$ dea
Join portfolioProject..covidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Temp table
drop table if exists #populationVaccinated
create table #populationVaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
) 

insert into #populationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigInt,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From portfolioProject..covid_death$ dea
Join portfolioProject..covidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #populationVaccinated

-- Creating View to store data for later visualizations
drop view PopulationVaccinated
Create View PopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From portfolioProject..covid_death$ dea
Join portfolioProject..covidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


select * from PopulationVaccinated






