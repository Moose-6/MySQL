-- Exploritory Data Analysis
#no goal, just exploring

SELECT *
FROM layoffs_staging2;

#working with total_laid_off and percentage _laid_off
#percentage not supper helpful without compnay sizes 
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company 
ORDER BY 2 DESC;

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry 
ORDER BY 2 DESC;

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country 
ORDER BY 2 DESC;

#only three years recorded in 2023 and 9 months in 2020
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`) 
ORDER BY 1 DESC;

SELECT SUBSTRING(`date`, 1,7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC; 

#ROLLONG SUM
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1,7) AS `Month`, SUM(total_laid_off) AS Total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)
SELECT `Month`, Total_off,
SUM(Total_off) OVER(ORDER BY `Month`) AS rolling_total
FROM Rolling_Total;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`) 
ORDER BY 3 DESC;

#ranking companies by how many employees they laid off by the year
WITH company_year (Company, Years, Laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`) 
)
SELECT *, DENSE_RANK() OVER (PARTITION BY Years ORDER BY Laid_off DESC) AS ranking
FROM company_year
WHERE Years IS NOT NULL
ORDER BY ranking;

#looking at top 5 companies who laid off employees by year
WITH company_year (Company, Years, Laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`) 
), Company_Year_Ranking AS
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY Years ORDER BY Laid_off DESC) AS ranking
FROM company_year
WHERE Years IS NOT NULL
)
SELECT *
FROM Company_Year_Ranking
WHERE ranking <= 5;
