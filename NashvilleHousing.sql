/* 

Cleaning Data in SQL Queries to make the data more useable 

*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

--STANDARDISE DATA FORMAT

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

--This code updates the query properly because it didn't with just the UPDATE statement 

ALTER TABLE NashvilleHousing 
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

--POPULATE PROPERTY ADDRESS DATA

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL  

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL 

--In the data you can see some ParcelID's are the same and they have the same address 

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

--So if one ParcelID has an address and there is a copy of the same ParcelID without an address it can be populated with the same address 
--JOIN is used to check if ParcelID is the same but not in the same row then the addresses need to be equal
--ISNULL checks to see if a.PropertyAddress is null, if it is null it can be populated with a value  

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL 

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

--Seperating using a substring and a charindex

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address 
FROM PortfolioProject.dbo.NashvilleHousing

--CHARINDEX specifies a position and we can see the position of the delimiter 

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address,
CHARINDEX(',', PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing

--Removing the comma 

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address 
FROM PortfolioProject.dbo.NashvilleHousing

--Separating out city 

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) AS Address
FROM PortfolioProject.dbo.NashvilleHousing

--Creating two new columns because two values cannot be seperated from one column 

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE NashvilleHousing 
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress))

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

--Owner Address (Address, City, State)

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

--Using Parsename which only works with periods so REPLACE commas with periods
--Parsename does things in reverse because we can see that we get the state first 

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

--Parsename separates everthing automatically but backwards

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
FROM PortfolioProject.dbo.NashvilleHousing

--Putting it in the right way round

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM PortfolioProject.dbo.NashvilleHousing 

--Adding columns 

ALTER TABLE NashvilleHousing 
ADD OwnerSplitAddress NVARCHAR(255);
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);
ALTER TABLE NashvilleHousing 
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing

--CHANGE Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

--Change Y & N to Yes and No because they are more populated done through a case statement 

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

--REMOVE DUPLICATES (Not standard practice but just as an example)

SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
				 
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

--Using a CTE, kind of like a temp table 

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
				 
FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--There is multiple rows or columns that are duplicates that will be deleted 

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
				 
FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--Check using original CTE query 

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
				 
FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--DELETE UNUSED COLUMNS (Do not do this to raw data!!!!)
--Just for example purposes here
--Property split and owner split are much more useful than property address and owner address, so they will be deleted 

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, 

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate, TaxDistrict

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
