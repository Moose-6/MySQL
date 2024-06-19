-- Data Cleaning --

SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize Data
-- 3. Null/Blank values 
-- 4. Remove any columns (Sometimes not necessary)

-- 1 --
# Create a seperate table to do the cleaning on
# We shouldn't work on the raw data
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

# accidently ran twice, so everything is duplicated
# changed table from layoff_staging to layoff_stage to reset 
INSERT layoffs_staging
SELECT * 
FROM layoffs;


WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

#checking to see if they are indeed duplicates
#we see that outside of the accidental duplicates that there are some entries that look very close to identical, but are not
#we will now add evey column to the cte (only company, industry, total_laid_off, percentage_laid_off, 'date' before) 
SELECT *
FROM layoffs_staging
WHERE company = 'Better.com';

#check with new company since Oda doesn't have duplicates 
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

#now delete these duplicates 
#we can't change the cte to delete instead of select

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2
WHERE company = 'Hibob';

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- 2 --
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

#here we noticed three different entries for Crypto 
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;
#check to see what percentage follows which title
SELECT * 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; 
#we see that 97% of the titles are 'Crypto' so we will change the others to that
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; 

#No anomolies 
SELECT DISTINCT location 
FROM layoffs_staging2
ORDER BY 1;

#There are two different United States entries
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(Trailing '.' From country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(Trailing '.' From country)
WHERE country LIKE 'United States%'; 

#change date column from text to date
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

#This is still a text but now we can change the data type
SELECT `date`
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
modify COLUMN `date` DATE;

-- 3
#layoff_total and layoff_percentage can't be populated unless we knew the amount of employees and the percentage laidoff 
#we don't care about the funds raised so we will just ignore poulating that

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

#looking for populated data within these nulls and blanks 
#we see that industry for Airbnb in Travel
#Bally's doesn't have a populated industry so it will remain as null
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

#we want to replace nulls with populated info
#first we need to turn any blanks into nulls 
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
#finding all the nulls will popluated data
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company 
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;
#now we want to update the table filling nulls with populated data
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- 4 
#we need to see what null values will not be helfpul

#we don't know if there were any layoffs in this data
#we are confident enough that this will not be helpful for quering the data because we can say its inaccurate  
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

#dropping this row since we added it in for cleaning purposes 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

#this is our final product...the cleaned data that we can now query
SELECT *
FROM layoffs_staging2